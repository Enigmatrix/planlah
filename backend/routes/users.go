package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

type CreateUserDto struct {
	Name      string `json:"name" binding:"required"`
	AuthToken string `json:"authToken" binding:"required"`
	// TODO fields representing data collected from user questionnaire
}

// Ping
// @Summary Ping
// @Router /api/users/ping [get]
func Ping(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, gin.H{"message": "pong"})
}

// Create a new user
// @Param body body CreateUserDto true "Details of newly created user"
// @Router /api/users/create [post]
func Create(ctx *gin.Context) {
	var createUserDto CreateUserDto
	if err := Body(ctx, &createUserDto); err != nil {
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": createUserDto.Name})
}

// Login a user
// @Param body body CreateUserDto true "Details of user profile"
// @Router /api/users/login [post]
func Login(ctx *gin.Context) {
	var createUserDto CreateUserDto
	if err := Body(ctx, &createUserDto); err != nil {
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": createUserDto.Name})
}

func Register(router *gin.RouterGroup) {
	users := router.Group("users")
	{
		users.GET("ping", Ping)
		users.POST("create", Create)
		users.POST("login", Login)
	}
}
