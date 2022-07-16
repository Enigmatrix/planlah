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

type UserUpdate struct {
	UpdateKind
}

type GroupUpdate struct {
	UpdateKind
}

type MessageUpdate struct {
	UpdateKind
}

type OutingUpdate struct {
	UpdateKind
}

func NewUserUpdate() UserUpdate {
	return UserUpdate{
		UpdateKind{Kind: "user"},
	}
}

func NewGroupUpdate() GroupUpdate {
	return GroupUpdate{
		UpdateKind{Kind: "group"},
	}
}

func NewMessageUpdate() MessageUpdate {
	return MessageUpdate{
		UpdateKind{Kind: "message"},
	}
}

func NewOutingUpdate() OutingUpdate {
	return OutingUpdate{
		UpdateKind{Kind: "outing"},
	}
}

type UpdateHub struct {
	// Map<UserId, Set<UpdateClient>>
	userClientMapping map[uint]map[*UpdateClient]bool

	messages   chan targetedMsg
	register   chan *UpdateClient
	unregister chan *UpdateClient

	db *data.Database
}

var updateHub lazy.Lazy[*UpdateHub]

// NewUpdateHub Creates a singleton Hub
func NewUpdateHub(db *data.Database) *UpdateHub {
	return updateHub.LazyValue(func() *UpdateHub {
		return &UpdateHub{
			userClientMapping: make(map[uint]map[*UpdateClient]bool),
			messages:          make(chan targetedMsg),
			register:          make(chan *UpdateClient),
			unregister:        make(chan *UpdateClient),
			db:                db,
		}
	})
}

func (h *UpdateHub) SendToGroup(groupId uint, msg any) error {
	members, err := h.db.GetAllGroupMembers(groupId)
	if err != nil {
		return errors.Trace(err)
	}
	for _, member := range members {
		h.messages <- targetedMsg{userId: member.ID, msg: msg}
	}
	return nil
}

func (h *UpdateHub) SendToUser(userId uint, msg any) error {
	h.messages <- targetedMsg{userId: userId, msg: msg}
	return nil
}

func (h *UpdateHub) Run() {
	for {
		select {
		case client := <-h.register:
			userClients, found := h.userClientMapping[client.userId]
			if !found {
				userClients = make(map[*UpdateClient]bool)
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
				case client.send <- message:
				default: // client error/forced disconnect
					h.unregister <- client
				}
			}
		}
	}
}
