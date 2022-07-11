package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/juju/errors"
	"github.com/samber/lo"
	"net/http"
	"planlah.sg/backend/data"
)

type FriendsController struct {
	BaseController
}

type ListFriendsDto struct {
	data.Pagination
}

type ListFriendRequestsDto struct {
	data.Pagination
}

type CreateFriendRequestDto struct {
	UserID uint `json:"id" binding:"required"`
}

type FriendRequestDto struct {
	From UserSummaryDto `json:"from" binding:"required"`
}
type FriendRequestRefDto struct {
	UserID uint `json:"userId" binding:"required"`
}

// SendFriendRequest godoc
// @Summary Send a friend request
// @Description Send a friend request to the specified user. If the specified user is the current user, this fails.
// @Description If the specified user has previously sent a friend request to the current user, that friend request is approved.
// @Param body body CreateFriendRequestDto true "Friend Request"
// @Tags Friends
// @Success 200 {object} data.FriendRequestStatus
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/send [post]
func (ctr *FriendsController) SendFriendRequest(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto CreateFriendRequestDto
	if Body(ctx, &dto) {
		return
	}

	status, err := ctr.Database.SendFriendRequest(userId, dto.UserID)
	if err != nil {
		if errors.Is(err, data.IsSameUser) {
			FailWithMessage(ctx, "users are the same")
			return
		}
		if errors.Is(err, data.EntityNotFound) {
			FailWithMessage(ctx, "user not found")
			return
		}
		if errors.Is(err, data.FriendRequestExists) {
			FailWithMessage(ctx, "friend request exists")
			return
		}
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, status)
}

// ApproveFriendRequest godoc
// @Summary Approve a friend request
// @Description Approve a friend request. If the status is already accepted/rejected, this is ignored
// @Param body body FriendRequestRefDto true "Friend Request"
// @Tags Friends
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/approve [put]
func (ctr *FriendsController) ApproveFriendRequest(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto FriendRequestRefDto
	if Body(ctx, &dto) {
		return
	}

	err := ctr.Database.ApproveFriendRequest(dto.UserID, userId)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
}

// RejectFriendRequest godoc
// @Summary  Reject a friend request
// @Description Reject a friend request. If the status is already accepted/rejected, this is ignored
// @Param body body FriendRequestRefDto true "Friend Request"
// @Tags Friends
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/reject [put]
func (ctr *FriendsController) RejectFriendRequest(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto FriendRequestRefDto
	if Body(ctx, &dto) {
		return
	}

	err := ctr.Database.RejectFriendRequest(dto.UserID, userId)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
}

// ListFriendRequests godoc
// @Summary List all your friend requests.
// @Description List all your friend requests. Increment the {page} variable to view the next (by default 10) friend requests.
// @Param query query ListFriendRequestsDto true "body"
// @Security JWT
// @Tags Friends
// @Success 200 {object} []FriendRequestDto
// @Failure 401 {object} services.AuthError
// @Router /api/friends/requests/all [get]
func (ctr *FriendsController) ListFriendRequests(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto ListFriendRequestsDto
	if Query(ctx, &dto) {
		return
	}

	reqs, err := ctr.Database.PendingFriendRequests(userId, dto.Pagination)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, lo.Map(reqs, func(t data.FriendRequest, _ int) FriendRequestDto {
		return FriendRequestDto{
			From: ToUserSummaryDto(*t.From),
		}
	}))
}

// ListFriends godoc
// @Summary List all your friends
// @Description List all your friends . Increment the {page} variable to view the next (by default 10) users.
// @Param query query ListFriendsDto true "body"
// @Security JWT
// @Tags Friends
// @Success 200 {object} []UserSummaryDto
// @Failure 401 {object} services.AuthError
// @Router /api/friends/all [get]
func (ctr *FriendsController) ListFriends(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto ListFriendsDto
	if Query(ctx, &dto) {
		return
	}

	reqs, err := ctr.Database.ListFriends(userId, dto.Pagination)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, lo.Map(reqs, func(t data.User, _ int) UserSummaryDto {
		return ToUserSummaryDto(t)
	}))
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
