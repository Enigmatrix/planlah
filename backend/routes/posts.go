package routes

import (
	"github.com/gin-gonic/gin"
	"time"
)

type PostsController struct {
	BaseController
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

// Front end -> User makes a request -> We get his user id
// From his user id -> We get his friends -> From his friends -> Get their posts
func (ctr *PostsController) GetPosts(ctx *gin.Context) {

}