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

func (ctr *DevPanelController) AddToDefaultGroups(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	for i := 1; i <= 3; i++ {
		_, err := ctr.Database.AddUserToGroup(userId, uint(i))
		if err != nil {
			if err == data.UserAlreadyInGroup {
				continue
			} else {
				handleDbError(ctx, err)
				return
			}
		}
	}
	ctx.Status(http.StatusOK)
}

// Register the routes for this controller
func (ctr *DevPanelController) Register(router *gin.RouterGroup) {
	if ctr.Config.AppMode == utils.Dev || ctr.Config.AppMode == utils.Orbital {
		users := router.Group("dev_panel")
		users.POST("add_to_default_groups", ctr.AddToDefaultGroups)
	}
}
