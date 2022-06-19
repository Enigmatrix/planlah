package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
	"planlah.sg/backend/utils"
)

type DevPanelController struct {
	Database *data.Database
	Auth     *services.AuthService
	Config   *utils.Config
}

func (controller DevPanelController) AddToDefaultGroups(ctx *gin.Context) {
	userId := controller.Auth.AuthenticatedUserId(ctx)
	for i := 1; i <= 3; i++ {
		_, err := controller.Database.AddUserToGroup(userId, uint(i))
		if err != nil {
			ctx.JSON(http.StatusBadRequest, NewErrorMessage(err.Error()))
			return
		}
	}
	ctx.Status(http.StatusOK)
}

// Register the routes for this controller
func (controller DevPanelController) Register(router *gin.RouterGroup) {
	if controller.Config.AppMode == utils.Dev || controller.Config.AppMode == utils.Orbital {
		users := router.Group("dev_panel")
		users.POST("add_to_default_groups", controller.AddToDefaultGroups)
	}
}
