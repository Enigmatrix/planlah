package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

type SessionController struct {
	BaseController
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  2048,
	WriteBufferSize: 2048,
}

// Register the routes for this controller
func (ctr *SessionController) Register(router *gin.RouterGroup) {
	users := router.Group("session")
	users.GET("updates", ctr.Connect)
}

// TODO write doc for this
func (ctr *SessionController) Connect(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)
	ws, err := upgrader.Upgrade(ctx.Writer, ctx.Request, nil)
	if err != nil {
		// Upgrade will set the correct HTTP status
		return
	}
}
