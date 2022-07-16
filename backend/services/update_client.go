package services

import (
	"github.com/gorilla/websocket"
	"net/http"
	"time"
)

// https://github.com/gorilla/websocket/blob/master/examples/chat/client.go

type UpdateClient struct {
	hub    *UpdateHub
	userId uint
	conn   *websocket.Conn
	send   chan interface{}
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer.
	maxMessageSize = 1024
)

// writePump pumps messages from the hub to the websocket connection.
//
// A goroutine running writePump is started for each connection. The
// application ensures that there is at most one writer to a connection by
// executing all writes from this goroutine.
func (c *UpdateClient) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		_ = c.conn.Close()
	}()
	for {
		select {
		case message, ok := <-c.send:
			if c.conn.SetWriteDeadline(time.Now().Add(writeWait)) != nil {
				return
			}

			if !ok {
				// The hub closed the channel. Don't care about any errors
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			err := c.conn.WriteJSON(message)
			if err != nil {
				return
			}

		case <-ticker.C:
			if c.conn.SetWriteDeadline(time.Now().Add(writeWait)) != nil {
				return
			}
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func SetupUpdateClient(hub *UpdateHub, w http.ResponseWriter, r *http.Request, userId uint) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		// Update will write the proper HTTP headers
		return
	}
	client := &UpdateClient{hub: hub, conn: conn, send: make(chan interface{}), userId: userId}
	client.hub.register <- client

	// Allow collection of memory referenced by the caller by doing all work in
	// new goroutines.
	go client.writePump()
}
