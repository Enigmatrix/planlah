package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"net/http"
	"planlah.sg/backend/data"
)

type ReviewsController struct {
	BaseController
}

type CreateReviewDto struct {
	PlaceID uint   `form:"place_id" binding:"required"`
	Content string `form:"content" binding:"required"`
	Rating  uint   `form:"rating" binding:"required"`
}

type SearchForReviewsDto struct {
	PlaceID uint `form:"query" binding:"required"`
	Page    data.Pagination
}

type ReviewDto struct {
	ID      uint           `json:"id" binding:"required"`
	User    UserSummaryDto `json:"user" binding:"required"`
	Place   PlaceDto       `json:"place" binding:"required"`
	Content string         `json:"content" binding:"required"`
	Rating  uint           `json:"rating" binding:"required"`
}

func ToReviewDto(review data.Review) ReviewDto {
	return ReviewDto{
		ID:      review.ID,
		User:    ToUserSummaryDto(*review.User),
		Place:   ToPlaceDto(review.Place),
		Content: review.Content,
		Rating:  review.Rating,
	}
}

func ToReviewDtos(reviews []data.Review) []ReviewDto {
	return lo.Map(reviews, func(r data.Review, _ int) ReviewDto {
		return ToReviewDto(r)
	})
}

// CreateReview godoc
// @Summary Create a review for a place
// @Description Create a review for a place
// @Param form formData CreateReviewDto true "body"
// @Tags Reviews
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/reviews/create [post]
func (ctr ReviewsController) CreateReview(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto CreateReviewDto
	if Form(ctx, &dto) {
		return
	}

	review := data.Review{
		UserID:  userId,
		PlaceID: dto.PlaceID,
		Content: dto.Content,
		Rating:  dto.Rating,
	}

	err := ctr.Database.CreateReview(&review)

	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
}

// GetReviews godoc
// @Summary Get reviews with pagination
// @Description Get reviews for this place given page number
// @Param query query SearchForReviewsDto true "body"
// @Tags Reviews
// @Security JWT
// @Success 200 {object} []ReviewDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/reviews/get [get]
func (ctr ReviewsController) GetReviews(ctx *gin.Context) {
	var dto SearchForReviewsDto
	if Query(ctx, &dto) {
		return
	}

	reviews, err := ctr.Database.GetReviews(dto.PlaceID, dto.Page)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToReviewDtos(reviews))
}

// Register the routes for this controller
func (ctr *ReviewsController) Register(router *gin.RouterGroup) {
	reviews := router.Group("reviews")
	reviews.GET("get", ctr.GetReviews)
	reviews.POST("create", ctr.CreateReview)
}
