package services

import (
	"github.com/juju/errors"
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

func NewUserUpdate() *UserUpdate {
	return &UserUpdate{
		UpdateKind{Kind: "user"},
	}
}

func NewGroupUpdate(groupId uint) *GroupUpdate {
	return &GroupUpdate{
		UpdateKind: UpdateKind{Kind: "group"},
		GroupID:    groupId,
	}
}

func NewGroupsUpdate() *GroupsUpdate {
	return &GroupsUpdate{
		UpdateKind: UpdateKind{Kind: "groups"},
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

type WebsocketUpdateHub struct {
	// Map<UserId, Set<WebsocketUpdateClient>>
	userClientMapping map[uint]map[*WebsocketUpdateClient]bool

	messages   chan targetedMsg
	register   chan *WebsocketUpdateClient
	unregister chan *WebsocketUpdateClient

	db *data.Database
}

var updateHub = lazy.NewLazy[*WebsocketUpdateHub]()

// NewWebsocketUpdateHub Creates a singleton Hub
func NewWebsocketUpdateHub(db *data.Database) *WebsocketUpdateHub {
	return updateHub.LazyValue(func() *WebsocketUpdateHub {
		return &WebsocketUpdateHub{
			userClientMapping: make(map[uint]map[*WebsocketUpdateClient]bool),
			messages:          make(chan targetedMsg),
			register:          make(chan *WebsocketUpdateClient),
			unregister:        make(chan *WebsocketUpdateClient),
			db:                db,
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

func (h *WebsocketUpdateHub) Run() {
	for {
		select {
		case client := <-h.register:
			userClients, found := h.userClientMapping[client.userId]
			if !found {
				userClients = make(map[*WebsocketUpdateClient]bool)
				h.userClientMapping[client.userId] = userClients
			}
			userClients[client] = true

		case client := <-h.unregister:
			userClients, found := h.userClientMapping[client.userId]
			if !found {
				continue
			}
			if _, ok := userClients[client]; ok {
				delete(userClients, client)
				close(client.send)
			}
			if len(userClients) == 0 {
				delete(h.userClientMapping, client.userId)
			}

		case message := <-h.messages:
			for client := range h.userClientMapping[message.userId] {
				select {
				case client.send <- message.msg:
				default:
					h.unregister <- client
				}
			}
		}
	}
}

type UpdateHub interface {
	SendToGroup(groupId uint, msg any) error
	SendToUser(userId uint, msg any) error
	Run()
}
