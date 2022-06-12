package routes

import (
	"github.com/gin-gonic/gin"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
)

type ItineraryController struct {
	Database *data.Database
	Auth     *services.AuthService
}

// Create godoc
// @Summary Create a new itinerary
// @Description Create a new itinerary plan
// @Param body body CreateUserDto true "Initial details of Itinerary"
// @Tags User
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/itinerary/create [post]
func (controller *ItineraryController) Create(ctx *gin.Context) {
}

// Register the routes for this controller
func (controller *ItineraryController) Register(router *gin.RouterGroup) {
	group := router.Group("itinerary")
	group.POST("create", controller.Create)
}
