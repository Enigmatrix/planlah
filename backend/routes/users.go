package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/juju/errors"
	"github.com/lib/pq"
	"github.com/samber/lo"
	"go.uber.org/zap"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
)

type UserController struct {
	BaseController
	ImageService services.ImageService
	logger       *zap.Logger
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

func ToUserSummaryDto(user data.User) UserSummaryDto {
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
	var dto CreateUserDto
	if Form(ctx, &dto) {
		return
	}

	// maybe only allow upto a certain file size in meta (_ in below line)
	file, _, err := ctx.Request.FormFile("image")
	if err != nil {
		FailWithMessage(ctx, "image file field missing")
		return
	}

	imageUrl, err := controller.ImageService.UploadUserImage(file)
	if err != nil {
		// TODO handle this
		return
	}

	firebaseUid, err := controller.Auth.GetFirebaseUid(dto.FirebaseToken)
	if err != nil {
		controller.logger.Warn("firebase error", zap.Error(err))
		// TODO make this prettier
		ctx.JSON(http.StatusUnauthorized, gin.H{"message": "invalid firebase token"})
		return
	}

	// TODO all these FailWithMessages should be validation messages

	genderValidated := lo.Contains(GetGenders(), dto.Gender)
	if !genderValidated {
		FailWithMessage(ctx, "gender not recognized")
		return
	}

	attractionVector, err := calculateAttractionVector(dto.Attractions)
	if err != nil {
		FailWithMessage(ctx, "not enough attractions chosen")
		return
	}

	foodVector, err := calculateFoodVector(dto.Food)
	if err != nil {
		FailWithMessage(ctx, "not enough food chosen")
		return
	}

	user := data.User{
		Name:        dto.Name,
		Username:    dto.Username,
		Gender:      dto.Gender,
		Town:        dto.Town,
		FirebaseUid: *firebaseUid,
		ImageLink:   imageUrl,
		Attractions: attractionVector,
		Food:        foodVector,
	}

	err = controller.Database.CreateUser(&user)
	if err != nil {
		// TODO handle user failure stuff
		if err == data.UsernameExists {
			FailWithMessage(ctx, "username exists")
			return
		} else if err == data.FirebaseUidExists {
			FailWithMessage(ctx, "account already exists for this user")
			return
		}
		handleDbError(ctx, err)
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
func (controller *UserController) GetInfo(ctx *gin.Context) {
	userId := controller.AuthUserId(ctx)

	user, err := controller.Database.GetUser(userId)
	if err != nil { // this User is always found
		handleDbError(ctx, err)
		return
	}

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
func (controller *UserController) Register(router *gin.RouterGroup) {
	users := router.Group("users")
	users.GET("me/info", controller.GetInfo)
}
