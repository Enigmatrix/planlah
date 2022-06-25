package routes

import (
	"errors"
	"net/http"
	"planlah.sg/backend/services"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
	"github.com/samber/lo"
	"planlah.sg/backend/data"
)

type UserController struct {
	BaseController
	ImageService services.ImageService
}

type UserSummaryDto struct {
	Username  string `json:"username" binding:"required"`
	Name      string `json:"name" binding:"required"`
	ImageLink string `json:"imageLink" binding:"required"`
}

type CreateUserDto struct {
	Name          string   `form:"name" binding:"required"`
	Username      string   `form:"username" binding:"required"`
	Gender        string   `form:"gender" binding:"required"`
	Town          string   `form:"town" binding:"required"`
	FirebaseToken string   `form:"firebaseToken" binding:"required"`
	Attractions   []string `form:"attractions" binding:"required"`
	Food          []string `form:"food" binding:"required"`
}

func ToUserSummaryDto(user *data.User) UserSummaryDto {
	return UserSummaryDto{
		Username:  user.Username,
		Name:      user.Name,
		ImageLink: user.ImageLink,
	}
}

// Create godoc
// @Summary Create a new User
// @Description Create a new User given a `CreateUserDto`.
// @Param form formData CreateUserDto true "Details of newly created user"
// @Param        image  formData  file  true  "User Image"
// @Accept       multipart/form-data
// @Tags User
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/users/create [post]
func (controller *UserController) Create(ctx *gin.Context) {
	var createUserDto CreateUserDto
	if err := Form(ctx, &createUserDto); err != nil {
		return
	}

	// maybe only allow upto a certain file size in meta (_ in below line)
	file, _, err := ctx.Request.FormFile("image")

	if err != nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("image file field missing"))
		return
	}

	imageUrl := controller.ImageService.UploadUserImage(file)

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
		ImageLink:   imageUrl,
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
	ctx.JSON(http.StatusOK, ToUserSummaryDto(user))
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
