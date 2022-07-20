package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/juju/errors"
	"github.com/samber/lo"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
	"time"
)

type PostsController struct {
	BaseController
	ImageService services.ImageService
}

type ListPostsDto struct {
	Page data.Pagination
}

type ListPostsByUser struct {
	Page   data.Pagination
	UserID uint `form:"userId" binding:"required"`
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

type CreatePostDto struct {
	Text         string `form:"text" binding:"required"`
	OutingStepID uint   `form:"outingStepId" binding:"required"`
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

	reqs, err := ctr.Database.SearchForPosts(userId, dto.Page)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, lo.Map(reqs, func(t data.Post, _ int) PostDto {
		return ToPostDto(t)
	}))
}

// ByUser godoc
// @Summary Get all posts by a specific user
// @Description Get all posts made by a specific user. Increment the {page} variable to view the next (by default 10) posts.
// @Param query query ListPostsByUser true "body"
// @Security JWT
// @Tags Posts
// @Success 200 {object} []PostDto
// @Failure 401 {object} services.AuthError
// @Router /api/posts/by_user [get]
func (ctr *PostsController) ByUser(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto ListPostsByUser
	if Query(ctx, &dto) {
		return
	}

	// if the target UserID is not the current user or not his friends, reject the request
	if userId != dto.UserID {
		isFriend, err := ctr.Database.IsFriend(userId, dto.UserID)
		if err != nil {
			handleDbError(ctx, err)
			return
		}
		if !isFriend {
			FailWithMessage(ctx, "users are not friends")
			return
		}
	}

	reqs, err := ctr.Database.SearchForPostsByUser(dto.UserID, dto.Page)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, lo.Map(reqs, func(t data.Post, _ int) PostDto {
		return ToPostDto(t)
	}))
}

// CreatePost godoc
// @Summary Create a new Post
// @Description Create a new Post given a `CreatePostDto`.
// @Param form formData CreatePostDto true "Details of newly created post"
// @Param        image  formData  file  true  "Post Image"
// @Accept       multipart/form-data
// @Tags Posts
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/posts/create [post]
func (ctr *PostsController) CreatePost(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto CreatePostDto
	if Form(ctx, &dto) {
		return
	}

	// maybe only allow upto a certain file size in meta (_ in below line)
	file, _, err := ctx.Request.FormFile("image")
	if err != nil {
		FailWithMessage(ctx, "image file field missing")
		return
	}

	imageUrl, err := ctr.ImageService.UploadPostImage(file)
	if err != nil {
		// TODO handle this
		return
	}

	o, err := ctr.Database.GetOutingAndGroupForOutingStep(dto.OutingStepID)
	if errors.Is(err, data.EntityNotFound) {
		FailWithMessage(ctx, "outing step not found")
		return
	} else if err != nil {
		handleDbError(ctx, err)
		return
	}

	grpMember := ctr.AuthGroupMember(ctx, o.GroupID)
	if grpMember == nil {
		return
	}

	post := data.Post{
		UserID:       userId,
		OutingStepID: dto.OutingStepID,
		Text:         dto.Text,
		ImageLink:    imageUrl,
		PostedAt:     time.Now().In(time.UTC),
	}
	err = ctr.Database.CreatePost(&post)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	err = ctr.Hub.SendToFriends(userId, services.NewPostUpdate(userId))
	handleHubError(ctr.Logger, err)

	ctx.Status(http.StatusOK)
}

func (ctr *PostsController) Register(router *gin.RouterGroup) {
	posts := router.Group("posts")
	posts.GET("all", ctr.GetAll)
	posts.GET("by_user", ctr.ByUser)
	posts.POST("create", ctr.CreatePost)
}
