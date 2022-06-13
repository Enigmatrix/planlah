package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
)

type UserController struct {
	Database *data.Database
	Auth     *services.AuthService
}

type UserSummaryDto struct {
	Nickname string `json:"nickname" binding:"required"`
	Name     string `json:"name" binding:"required"`
}

type CreateUserDto struct {
	Name          string   `json:"name" binding:"required"`
	Username      string   `json:"username" binding:"required"`
	Gender        string   `json:"gender" binding:"required"`
	Town          string   `json:"town" binding:"required"`
	FirebaseToken string   `json:"firebaseToken" binding:"required"`
	Attractions   []string `json:"attractions" binding:"required"`
	Food          []string `json:"food" binding:"required"`
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

	genderValidated := lo.Contains(genders, createUserDto.Gender)
	if !genderValidated {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("Gender not recognized"))
	}

	// TODO: Do feature calculations here

	user := data.User{
		Name:        createUserDto.Name,
		Username:    createUserDto.Username,
		Gender:      createUserDto.Gender,
		Town:        createUserDto.Town,
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
