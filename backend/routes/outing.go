package routes

import (
	"github.com/gin-gonic/gin"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
)

type OutingController struct {
	Database *data.Database
	Auth     *services.AuthService
}

// Create godoc
// @Summary Create a new Outing
// @Description Create a new Outing plan
// @Param body body CreateUserDto true "Initial details of Outing"
// @Tags Outing
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/create [post]
func (controller *OutingController) Create(ctx *gin.Context) {

}

// Register the routes for this controller
func (controller *OutingController) Register(router *gin.RouterGroup) {
	group := router.Group("outing")
	group.POST("create", controller.Create)
}
