package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/utils"
)

type DevPanelController struct {
	BaseController
}

func (controller *DevPanelController) AddToDefaultGroups(ctx *gin.Context) {
	userId, err := controller.AuthUserId(ctx)
	if err != nil {
		return
	}

	for i := 1; i <= 3; i++ {
		_, err := controller.Database.AddUserToGroup(userId, uint(i))
		if err != nil {
			if err == data.UserAlreadyInGroup {
				continue
			} else {
				return
			}
		}
	}
	ctx.Status(http.StatusOK)
}

// Register the routes for this controller
func (controller *DevPanelController) Register(router *gin.RouterGroup) {
	if controller.Config.AppMode == utils.Dev || controller.Config.AppMode == utils.Orbital {
		users := router.Group("dev_panel")
		users.POST("add_to_default_groups", controller.AddToDefaultGroups)
	}
}
