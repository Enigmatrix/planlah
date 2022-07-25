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
}

type UserSummaryDto struct {
	ID        uint   `json:"id" binding:"required"`
	Username  string `json:"username" binding:"required"`
	Name      string `json:"name" binding:"required"`
	ImageLink string `json:"imageLink" binding:"required"`
}

type UserProfileDto struct {
	UserSummaryDto
	PostCount   uint `json:"postCount" binding:"required"`
	ReviewCount uint `json:"reviewCount" binding:"required"`
	FriendCount uint `json:"friendCount" binding:"required"`
}

type UserRefDto struct {
	ID uint `json:"id,string" form:"id" query:"id" binding:"required"`
}

type CheckUserNameDto struct {
	UserName string `json:"username" form:"username" query:"username" binding:"required"`
}

type CheckUserNameResultDto struct {
	IsUnique bool `json:"isUnique" form:"isUnique" query:"isUnique" binding:"required"`
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

type SearchUsersDto struct {
	data.Pagination
	Query string `form:"query" binding:"required"`
}

func ToUserSummaryDto(user data.User) UserSummaryDto {
	return UserSummaryDto{
		ID:        user.ID,
		Username:  user.Username,
		Name:      user.Name,
		ImageLink: user.ImageLink,
	}
}

func ToUserProfileDto(profile data.UserProfile) UserProfileDto {
	return UserProfileDto{
		UserSummaryDto: ToUserSummaryDto(profile.User),
		PostCount:      profile.PostCount,
		ReviewCount:    profile.ReviewCount,
		FriendCount:    profile.FriendCount,
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
// @Failure 401 {object} services.AuthError
// @Router /api/users/create [post]
func (ctr *UserController) Create(ctx *gin.Context) {
	var dto CreateUserDto
	if Form(ctx, &dto) {
		return
	}

	file, meta, err := ctx.Request.FormFile("image")
	if err != nil {
		FailWithMessage(ctx, "image file field missing")
		return
	}

	if !ctr.ImageService.WithinLimits(meta.Size) {
		FailWithMessage(ctx, "image file too big!")
		return
	}
	imageUrl, err := ctr.ImageService.UploadUserImage(file, meta.Size)
	if err != nil {
		handleImageUploadError(ctx, err)
		return
	}

	firebaseUid, err := ctr.Auth.GetFirebaseUid(dto.FirebaseToken)
	if err != nil {
		ctr.Logger.Warn("firebase error", zap.Error(err))
		return
	}

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

	err = ctr.Database.CreateUser(&user)
	if err != nil {
		if errors.Is(err, data.UsernameExists) {
			FailWithMessage(ctx, "username exists")
			return
		} else if errors.Is(err, data.FirebaseUidExists) {
			FailWithMessage(ctx, "account already exists for this user")
			return
		}
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
}

// GetFriendInfo godoc
// @Summary Gets info about a friend
// @Description Gets info about a friend
// @Param query query UserRefDto true "body"
// @Security JWT
// @Tags User
// @Success 200 {object} UserProfileDto
// @Failure 401 {object} services.AuthError
// @Router /api/users/friend/info [get]
func (ctr *UserController) GetFriendInfo(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto UserRefDto
	if Query(ctx, &dto) {
		return
	}

	isFriend, err := ctr.Database.IsFriend(userId, dto.ID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}
	if !isFriend {
		FailWithMessage(ctx, "users are not friends")
		return
	}

	user, err := ctr.Database.GetUserProfile(dto.ID)
	if err != nil { // this User is always found
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToUserProfileDto(user))
}

// GetInfo godoc
// @Summary Gets info about the logged-in user
// @Description Gets info about a user (me = current user)
// @Security JWT
// @Tags User
// @Success 200 {object} UserProfileDto
// @Failure 401 {object} services.AuthError
// @Router /api/users/me/info [get]
func (ctr *UserController) GetInfo(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	user, err := ctr.Database.GetUserProfile(userId)
	if err != nil { // this User is always found
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToUserProfileDto(user))
}

// GetUserInfo godoc
// @Summary Gets info about a user given a user id
// @Description Gets info about a user given his user id
// @Param query query UserRefDto true "body"
// @Security JWT
// @Tags User
// @Success 200 {object} UserSummaryDto
// @Failure 401 {object} services.AuthError
// @Router /api/users/get [get]
func (ctr *UserController) GetUserInfo(ctx *gin.Context) {
	var dto UserRefDto
	if Query(ctx, &dto) {
		return
	}

	user, err := ctr.Database.GetUser(dto.ID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToUserSummaryDto(user))
}

// SearchForFriends godoc
// @Summary Search for friends
// @Description Search for users containing the specified text in their Name and Username and who are not already friends.
// @Description Increment the {page} variable to view the next (by default 10) users.
// @Param query query SearchUsersDto true "body"
// @Security JWT
// @Tags User
// @Success 200 {object} []UserSummaryDto
// @Failure 401 {object} services.AuthError
// @Router /api/users/search_for_friends [get]
func (ctr *UserController) SearchForFriends(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto SearchUsersDto
	if Query(ctx, &dto) {
		return
	}

	users, err := ctr.Database.SearchForFriends(userId, dto.Query, dto.Pagination)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, lo.Map(users, func(t data.User, _ int) UserSummaryDto {
		return ToUserSummaryDto(t)
	}))
}

// CheckUserName godoc
// @Summary Check if user name exists
// @Description Check if the user name is unique
// @Param query query CheckUserNameDto true "body"
// @Tags User
// @Success 200 {object} CheckUserNameResultDto
// @Router /api/users/check_user_name [get]
func (ctr *UserController) CheckUserName(ctx *gin.Context) {
	var dto CheckUserNameDto
	if Query(ctx, &dto) {
		return
	}

	isUnique, err := ctr.Database.IsUserNameUnique(dto.UserName)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, CheckUserNameResultDto{IsUnique: isUnique})
}

// EditImage godoc
// @Summary Edit a User's image
// @Description Edit a User's image
// @Param        image  formData  file  true  "User Image"
// @Accept       multipart/form-data
// @Security JWT
// @Tags User
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/users/edit_image [put]
func (ctr *UserController) EditImage(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	file, meta, err := ctx.Request.FormFile("image")
	if err != nil {
		FailWithMessage(ctx, "image file field missing")
		return
	}

	if !ctr.ImageService.WithinLimits(meta.Size) {
		FailWithMessage(ctx, "image file too big!")
		return
	}

	imageUrl, err := ctr.ImageService.UploadUserImage(file, meta.Size)
	if err != nil {
		handleImageUploadError(ctx, err)
		return
	}

	err = ctr.Database.UpdateUserImage(userId, imageUrl)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
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
func (ctr *UserController) Register(router *gin.RouterGroup) {
	users := router.Group("users")
	users.PUT("edit_image", ctr.EditImage)
	users.GET("me/info", ctr.GetInfo)
	users.GET("friend/info", ctr.GetFriendInfo)
	users.GET("get", ctr.GetUserInfo)
	users.GET("search_for_friends", ctr.SearchForFriends)
}
