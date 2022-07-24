package services

import (
	"github.com/juju/errors"
	"go.uber.org/zap"
	"planlah.sg/backend/data"
	lazy "planlah.sg/backend/utils"
)

// https://github.com/gorilla/websocket/blob/master/examples/chat/hub.go

type targetedMsg struct {
	userId uint
	msg    any
}

type UpdateKind struct {
	Kind string `json:"kind"`
}

// UserUpdate Event when User information is updated
type UserUpdate struct {
	UpdateKind
}

// GroupUpdate Event when Group information is updated
type GroupUpdate struct {
	UpdateKind
	GroupID uint `json:"groupId"`
}

// GroupsUpdate Event when Groups of the User are updated (added/removed)
type GroupsUpdate struct {
	UpdateKind
	Added bool `json:"added"`
}

// PostUpdate Event when Post of the User are updated (added/removed)
type PostUpdate struct {
	UpdateKind
	UserID uint `json:"userId"`
}

// MessageUpdate Event when messages for a Group are changed (new message sent)
type MessageUpdate struct {
	UpdateKind
	GroupID uint `json:"groupId"`
}

// ActiveOutingUpdate Event when the ActiveOuting for a Group is updated
type ActiveOutingUpdate struct {
	UpdateKind
	GroupID uint `json:"groupId"`
}

type FriendRequestUpdate struct {
	UpdateKind
	UserID uint `json:"userId"`
}

func NewUserUpdate() *UserUpdate {
	return &UserUpdate{
		UpdateKind{Kind: "user"},
	}
}

func NewGroupMemberUpdate(groupId uint) *GroupUpdate {
	return &GroupUpdate{
		UpdateKind: UpdateKind{Kind: "group"},
		GroupID:    groupId,
	}
}

func NewGroupsUpdate(added bool) *GroupsUpdate {
	return &GroupsUpdate{
		UpdateKind: UpdateKind{Kind: "groups"},
		Added:      added,
	}
}

func NewPostUpdate(userId uint) *PostUpdate {
	return &PostUpdate{
		UpdateKind: UpdateKind{Kind: "post"},
		UserID:     userId,
	}
}

func NewMessageUpdate(groupId uint) *MessageUpdate {
	return &MessageUpdate{
		UpdateKind: UpdateKind{Kind: "message"},
		GroupID:    groupId,
	}
}

func NewActiveOutingUpdate(groupId uint) *ActiveOutingUpdate {
	return &ActiveOutingUpdate{
		UpdateKind: UpdateKind{Kind: "activeOuting"},
		GroupID:    groupId,
	}
}

func NewFriendRequestUpdate(userId uint) *FriendRequestUpdate {
	return &FriendRequestUpdate{
		UpdateKind: UpdateKind{"friendRequest"},
		UserID:     userId,
	}
}

type WebsocketUpdateHub struct {
	// Map<UserId, Set<WebsocketUpdateClient>>
	userClientMapping map[uint]map[*WebsocketUpdateClient]bool

	messages   chan targetedMsg
	register   chan *WebsocketUpdateClient
	unregister chan *WebsocketUpdateClient

	db     *data.Database
	logger *zap.Logger
}

var updateHub = lazy.NewLazy[*WebsocketUpdateHub]()

// NewWebsocketUpdateHub Creates a singleton Hub
func NewWebsocketUpdateHub(db *data.Database, logger *zap.Logger) *WebsocketUpdateHub {
	return updateHub.LazyValue(func() *WebsocketUpdateHub {
		return &WebsocketUpdateHub{
			userClientMapping: make(map[uint]map[*WebsocketUpdateClient]bool),
			messages:          make(chan targetedMsg),
			register:          make(chan *WebsocketUpdateClient),
			unregister:        make(chan *WebsocketUpdateClient),
			db:                db,
			logger:            logger,
		}
	})
}

func (h *WebsocketUpdateHub) SendToGroup(groupId uint, msg any) error {
	members, err := h.db.GetAllGroupMembers(groupId)
	if err != nil {
		return errors.Trace(err)
	}
	for _, member := range members {
		h.messages <- targetedMsg{userId: member.ID, msg: msg}
	}
	return nil
}

func (h *WebsocketUpdateHub) SendToUser(userId uint, msg any) error {
	h.messages <- targetedMsg{userId: userId, msg: msg}
	return nil
}

func (h *WebsocketUpdateHub) SendToFriends(userId uint, msg any) error {
	friends, err := h.db.ListAllFriendIDs(userId)
	if err != nil {
		return errors.Trace(err)
	}
	for _, friendId := range friends {
		h.messages <- targetedMsg{userId: friendId, msg: msg}
	}
	return nil
}

func (h *WebsocketUpdateHub) unregisterCb(client *WebsocketUpdateClient) {
	userClients, found := h.userClientMapping[client.userId]
	if !found {
		return
	}
	if _, ok := userClients[client]; ok {
		delete(userClients, client)
		close(client.send)
	}
	if len(userClients) == 0 {
		delete(h.userClientMapping, client.userId)
	}
}

func (h *WebsocketUpdateHub) Run() {
	for {
		select {
		case client := <-h.register:
			h.logger.Info("websocket, register", zap.Uint("userId", client.userId))
			userClients, found := h.userClientMapping[client.userId]
			if !found {
				userClients = make(map[*WebsocketUpdateClient]bool)
				h.userClientMapping[client.userId] = userClients
			}
			userClients[client] = true

		case client := <-h.unregister:
			h.logger.Info("websocket, unregister", zap.Uint("userId", client.userId))
			h.unregisterCb(client)

		case message := <-h.messages:
			for client := range h.userClientMapping[message.userId] {
				select {
				case client.send <- message.msg:
				default:
					h.logger.Info("websocket, unregister (by disconnect)", zap.Uint("userId", client.userId))
					h.unregisterCb(client)
				}
			}
		}
	}
}

type UpdateHub interface {
	SendToGroup(groupId uint, msg any) error
	SendToUser(userId uint, msg any) error
	SendToFriends(userId uint, msg any) error
	Run()
}
