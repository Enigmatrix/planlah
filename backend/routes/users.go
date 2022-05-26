package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
)

type UserController struct {
	Database *data.Database
	Auth     *services.AuthService
}

type CreateUserDto struct {
	Nickname      string `json:"nickname" binding:"required"`
	Name          string `json:"name" binding:"required"`
	FirebaseToken string `json:"firebaseToken" binding:"required"`
	// TODO fields representing data collected from user questionnaire
}

// Create godoc
// @Summary Create a new User
// @Description Create a new User given a `CreateUserDto`.
// @Param body body CreateUserDto true "Details of newly created user"
// @Tags User
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/users/create [post]
func (controller UserController) Create(ctx *gin.Context) {
	var createUserDto CreateUserDto
	if err := Body(ctx, &createUserDto); err != nil {
		return
	}

	firebaseUid, err := controller.Auth.GetFirebaseUid(createUserDto.FirebaseToken)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, NewErrorMessage(err.Error()))
		return
	}

	user := data.User{
		Nickname:    createUserDto.Nickname,
		Name:        createUserDto.Name,
		FirebaseUid: *firebaseUid,
	}

	err = controller.Database.CreateUser(&user)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage(err.Error()))
		return
	}

	ctx.Status(http.StatusOK)
}

// Register the routes for this controller
func (controller UserController) Register(router *gin.RouterGroup) {
	// group := router.Group("users")
	// group.POST("create", controller.Create)
}
