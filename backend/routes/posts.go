package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"net/http"
	"planlah.sg/backend/data"
	"time"
)

type PostsController struct {
	BaseController
}

type ListPostsDto struct {
	Page string `form:"page" query:"page" binding:"required"`
}

type MakePostDto struct {
}

type PostDto struct {
	ID         uint           `json:"id" binding:"required"`
	User       UserSummaryDto `json:"user" binding:"required"`
	OutingStep OutingStepDto  `json:"outingStep" binding:"required"`
	Text       string         `json:"text" binding:"required"`
	ImageLink  string         `json:"imageLink" binding:"required"`
	PostedAt   time.Time      `json:"posted_at" binding:"required"`
}

func ToPostDto(post data.Post) PostDto {
	return PostDto{
		ID:         post.ID,
		User:       ToUserSummaryDto(*post.User),
		OutingStep: ToOutingStepDto(*post.OutingStep),
		Text:       post.Text,
		ImageLink:  post.ImageLink,
		PostedAt:   post.PostedAt,
	}
}

// GetAll godoc
// @Summary Get all posts
// @Description Get all posts made by your friends . Increment the {page} variable to view the next (by default 10) posts.
// @Param query query ListPostsDto true "body"
// @Security JWT
// @Tags Posts
// @Success 200 {object} []PostDto
// @Failure 401 {object} services.AuthError
// @Router /api/posts/all [get]
func (ctr *PostsController) GetAll(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto ListPostsDto
	if Query(ctx, &dto) {
		return
	}

	pageNo, err := convertPageToUInt(dto.Page)
	if err != nil {
		FailWithMessage(ctx, "Failed to convert page to int")
	}

	reqs, err := ctr.Database.SearchForPosts(userId, pageNo)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, lo.Map(reqs, func(t data.Post, _ int) PostDto {
		return ToPostDto(t)
	}))
}

func (ctr *PostsController) Register(router *gin.RouterGroup) {
	posts := router.Group("posts")
	posts.GET("all", ctr.GetAll)
}

// Front end -> User makes a request -> We get his user id
// From his user id -> We get his friends -> From his friends -> Get their posts
func (ctr *PostsController) GetPosts(ctx *gin.Context) {

}
