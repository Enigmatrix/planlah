package routes

import (
	"github.com/gin-gonic/gin"
)

type FriendsController struct {
	BaseController
}

type ListFriendsDto struct {
	Pagination
}

type ListFriendRequestsDto struct {
	Pagination
}

type CreateFriendRequestDto struct {
	UserID uint `json:"id" binding:"required"`
}

type FriendRequestDto struct {
	ID   uint           `json:"id" binding:"required"`
	From UserSummaryDto `json:"from" binding:"required"`
}
type FriendRequestRefDto struct {
	ID uint `json:"id" binding:"required"`
}

// SendFriendRequest godoc
// @Summary [UNIMPL] Send a friend request
// @Description Send a friend request to the specified user. If the specified user is the current user, this fails.
// @Description If the specified user has previously sent a friend request to the current user, that friend request is approved.
// @Param body body CreateFriendRequestDto true "Friend Request"
// @Tags Friends
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/send [post]
func (ctr *FriendsController) SendFriendRequest(ctx *gin.Context) {
	panic("[UNIMPL]")
}

// ApproveFriendRequest godoc
// @Summary [UNIMPL] Approve a friend request
// @Description Approve a friend request. If the status is already accepted/rejected, this is ignored
// @Param body body FriendRequestRefDto true "Friend Request"
// @Tags Friends
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/approve [put]
func (ctr *FriendsController) ApproveFriendRequest(ctx *gin.Context) {
	panic("[UNIMPL]")
}

// RejectFriendRequest godoc
// @Summary [UNIMPL] Reject a friend request
// @Description Reject a friend request. If the status is already accepted/rejected, this is ignored
// @Param body body FriendRequestRefDto true "Friend Request"
// @Tags Friends
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/reject [put]
func (ctr *FriendsController) RejectFriendRequest(ctx *gin.Context) {
	panic("[UNIMPL]")
}

// ListFriendRequests godoc
// @Summary [UNIMPL] List all your friend requests.
// @Description List all your friend requests. Increment the {page} variable to view the next (by default 10) friend requests.
// @Param query query ListFriendRequestsDto true "body"
// @Security JWT
// @Tags Friends
// @Success 200 {object} []FriendRequestDto
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/all [get]
func (ctr *FriendsController) ListFriendRequests(ctx *gin.Context) {
	panic("[UNIMPL]")
}

// ListFriends godoc
// @Summary [UNIMPL] List all your friends
// @Description List all your friends . Increment the {page} variable to view the next (by default 10) users.
// @Param query query ListFriendsDto true "body"
// @Security JWT
// @Tags Friends
// @Success 200 {object} []UserSummaryDto
// @Failure 401 {object} services.AuthError
// @Router /api/friends/all [get]
func (ctr *FriendsController) ListFriends(ctx *gin.Context) {
	panic("[UNIMPL]")
}

// Register the routes for this controller
func (ctr *FriendsController) Register(router *gin.RouterGroup) {
	friends := router.Group("friends")
	friends.GET("all", ctr.ListFriends)
	friends.GET("requests/all", ctr.ListFriendRequests)
	friends.POST("requests/send", ctr.SendFriendRequest)
	friends.PUT("requests/approve", ctr.ApproveFriendRequest)
	friends.PUT("requests/reject", ctr.RejectFriendRequest)
}
