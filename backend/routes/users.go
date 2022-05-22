package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
)

type UserController struct {
	db   data.Database
	auth services.AuthService
}

type CreateUserDto struct {
	Nickname  string `json:"nickname" binding:"required"`
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
	firebaseUid, err := controller.auth.Verify(createUserDto.AuthToken)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, ErrorMessage{Message: "invalid credentials"})
		return
	}

	user := data.User{
		Nickname:    createUserDto.Nickname,
		Name:        createUserDto.Name,
		FirebaseUid: *firebaseUid,
	}

	controller.db.CreateUser(&user)

	// create gin-jwt

	ctx.JSON(http.StatusOK, TokenDto{Token: user.FirebaseUid})
}

// Register the routes for this controller
func (controller UserController) Register(router *gin.RouterGroup) {
	group := router.Group("users")
	group.POST("create", controller.Create)
}
