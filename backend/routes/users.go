package routes

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
	"github.com/samber/lo"
	"planlah.sg/backend/data"
)

type UserController struct {
	BaseController
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

	genderValidated := lo.Contains(GetGenders(), createUserDto.Gender)
	if !genderValidated {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("Gender not recognized"))
	}

	attractionVector, err := calculateAttractionVector(createUserDto.Attractions)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("Not enough attractions chosen"))
	}

	foodVector, err := calculateFoodVector(createUserDto.Food)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("Not enough food chosen"))
	}

	user := data.User{
		Name:        createUserDto.Name,
		Username:    createUserDto.Username,
		Gender:      createUserDto.Gender,
		Town:        createUserDto.Town,
		FirebaseUid: *firebaseUid,
		Attractions: attractionVector,
		Food:        foodVector,
	}

	err = controller.Database.CreateUser(&user)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage(err.Error()))
		return
	}

	ctx.Status(http.StatusOK)
}

// GetInfo godoc
// @Summary Gets info about a user
// @Description Gets info about a user (me = current user)
// @Security JWT
// @Tags User
// @Success 200 {object} UserSummaryDto
// @Failure 401 {object} ErrorMessage
// @Router /api/users/me/info [get]
func (controller UserController) GetInfo(ctx *gin.Context) {
	userId, err := controller.AuthUserId(ctx)
	if err != nil {
		return
	}

	user := controller.Database.GetUser(userId)
	ctx.JSON(http.StatusOK, &UserSummaryDto{
		Nickname: user.Username,
		Name:     user.Name,
	})
}

// TODO: To think of better ways to do this. For now its very simple 1/n standardization

func contains(s []string, str string) bool {
	for _, v := range s {
		if v == str {
			return true
		}
	}
	return false
}

func calculateVector(tags, allCategories []string) (pq.Float64Array, error) {
	n := float64(len(tags))
	featureVector := make([]float64, len(allCategories))
	if n < 5 {
		return nil, errors.New("")
	}

	for i, category := range allCategories {
		if contains(tags, category) {
			featureVector[i] = 1.00 / n
		} else {
			featureVector[i] = 0
		}
	}

	return featureVector, nil

}

func calculateAttractionVector(attractions []string) (pq.Float64Array, error) {
	vector, err := calculateVector(attractions, GetAttractions())
	if err != nil {
		return nil, errors.New("less then 5 attractions sent by user")
	}
	return vector, nil
}

func calculateFoodVector(food []string) (pq.Float64Array, error) {
	vector, err := calculateVector(food, GetFood())
	if err != nil {
		return nil, errors.New("less then 5 food sent by user")
	}
	return vector, nil
}

// Register the routes for this controller
func (controller UserController) Register(router *gin.RouterGroup) {
	users := router.Group("users")
	users.GET("me/info", controller.GetInfo)
}
