package routes

import "time"

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
