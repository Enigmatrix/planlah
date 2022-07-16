package routes

import (
	"github.com/gin-gonic/gin"
	"planlah.sg/backend/services"
)

type SessionController struct {
	BaseController
}

// Register the routes for this controller
func (ctr *SessionController) Register(router *gin.RouterGroup) {
	users := router.Group("session")
	users.Any("updates", ctr.Connect)
}

// TODO write doc for this
func (ctr *SessionController) Connect(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)
	services.SetupUpdateClient(ctr.Hub, ctx.Writer, ctx.Request, userId)
}
