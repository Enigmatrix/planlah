package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

type UserController struct {
}

type CreateUserDto struct {
	Name      string `json:"name" binding:"required"`
	AuthToken string `json:"authToken" binding:"required"`
	// TODO fields representing data collected from user questionnaire
}

// Create
// @Summary Create a new User
// @Param body body CreateUserDto true "Details of newly created user"
// @Router /api/users/create [post]
func (controller UserController) Create(ctx *gin.Context) {
	var createUserDto CreateUserDto
	if err := Body(ctx, &createUserDto); err != nil {
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": createUserDto.Name})
}

// Register the routes for this controller
func (controller UserController) Register(router *gin.RouterGroup) {
	group := router.Group("users")
	group.POST("create", controller.Create)
}
