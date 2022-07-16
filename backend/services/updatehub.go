package services

import (
	"github.com/gorilla/websocket"
	"github.com/juju/errors"
	"planlah.sg/backend/data"
	lazy "planlah.sg/backend/utils"
)

// https://github.com/gorilla/websocket/blob/master/examples/chat/client.go

type UpdateClient struct {
	hub    *UpdateHub
	userId uint
	conn   *websocket.Conn
	send   chan interface{}
}

type UserMsg struct {
	userId uint
	msg    any
}

type UpdateHub struct {
	// Map<UserId, Set<UpdateClient>>
	userClientMapping map[uint]map[*UpdateClient]bool

	messages   chan UserMsg
	register   chan *UpdateClient
	unregister chan *UpdateClient

	db *data.Database
}

var updateHub lazy.Lazy[*UpdateHub]

func NewUpdateHub(db *data.Database) *UpdateHub {
	return updateHub.LazyValue(func() *UpdateHub {
		return &UpdateHub{
			userClientMapping: make(map[uint]map[*UpdateClient]bool),
			messages:          make(chan UserMsg),
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
		h.messages <- UserMsg{userId: member.ID, msg: msg}
	}
	return nil
}

func (h *UpdateHub) SendToUser(userId uint, msg any) error {
	h.messages <- UserMsg{userId: userId, msg: msg}
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
