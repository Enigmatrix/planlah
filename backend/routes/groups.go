package routes

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/samber/lo"
	"log"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/utils"
	"time"
)

type GroupsController struct {
	BaseController
}

type CreateGroupDto struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description" binding:"required"`
}

type GroupSummaryDto struct {
	ID                  uint        `json:"id" binding:"required"`
	Name                string      `json:"name" binding:"required"`
	Description         string      `json:"description" binding:"required"`
	LastSeenMessage     *MessageDto `json:"lastSeenMessage"`
	UnreadMessagesCount uint        `json:"unreadMessagesCount" binding:"required"`
}

type GroupInviteDto struct {
	ID      string     `json:"id" binding:"required,uuid"`
	GroupID uint       `json:"groupId" binding:"required"`
	Url     string     `json:"url" binding:"required"`
	Expiry  *time.Time `json:"expiry"` // TODO add comment about null expiry
}

type GetGroupInvitesDto struct {
	GroupID uint `form:"groupId" json:"groupId" binding:"required"`
}

type CreateGroupInviteDto struct {
	ExpiryOption string `json:"expiryOption" binding:"required"` // TODO make this an enum
	GroupID      uint   `form:"groupId" json:"groupId" binding:"required"`
}

type InvalidateGroupInviteDto struct {
	InviteID string `json:"inviteId" binding:"required,uuid"`
}

type JoinGroupInviteDto struct {
	InviteID string `uri:"inviteId" json:"inviteId" binding:"required,uuid"`
}

type ExpiryOption string

const (
	OneHour ExpiryOption = "oneHour"
	OneDay               = "oneDay"
	Never                = "never"
)

func ToGroupInviteDto(invite data.GroupInvite, config *utils.Config) GroupInviteDto {
	return GroupInviteDto{
		ID:      invite.ID.String(),
		GroupID: invite.GroupID,
		Url:     fmt.Sprintf("%s/join/%s", config.BaseUrl, invite.ID.String()),
		Expiry:  invite.Expiry,
	}
}

// CreateInvite godoc
// @Summary Create an invitation link for a Group
// @Description Create an invitation link for a Group that expires after a certain period
// @Param body body CreateGroupInviteDto true "Details of expiring invitation link"
// @Tags Group
// @Security JWT
// @Success 200 {object} GroupInviteDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/invites/create [post]
func (controller GroupsController) CreateInvite(ctx *gin.Context) {
	var createGroupInviteDto CreateGroupInviteDto
	if err := Body(ctx, &createGroupInviteDto); err != nil {
		return
	}

	_, err := controller.AuthGroupMember(ctx, createGroupInviteDto.GroupID)
	if err != nil {
		return
	}

	var expiry *time.Time

	switch ExpiryOption(createGroupInviteDto.ExpiryOption) {
	case OneHour:
		t := time.Now().Add(time.Hour)
		expiry = &t
	case OneDay:
		t := time.Now().Add(time.Hour * 24)
		expiry = &t
	case Never:
		expiry = nil
	default:
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("invalid expiryOption"))
		return
	}

	invite := data.GroupInvite{
		Expiry:  expiry,
		GroupID: createGroupInviteDto.GroupID,
		Active:  true,
	}

	err = controller.Database.CreateGroupInvite(&invite)

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	ctx.JSON(http.StatusOK, ToGroupInviteDto(invite, controller.Config))
}

// InvalidateInvite godoc
// @Summary Invalidates an invitation
// @Description Invalidates an invitation so that no one else can join
// @Param body body InvalidateGroupInviteDto true "Details of invite to invalidate"
// @Tags Group
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/invites/invalidate [put]
func (controller GroupsController) InvalidateInvite(ctx *gin.Context) {
	userId, err := controller.AuthUserId(ctx)
	if err != nil {
		return
	}

	var invalidateGroupInviteDto InvalidateGroupInviteDto
	if err := Body(ctx, &invalidateGroupInviteDto); err != nil {
		return
	}

	// This will definitely pass, since we have a validator checking
	// the UUID format
	inviteId := uuid.MustParse(invalidateGroupInviteDto.InviteID)

	err = controller.Database.InvalidateInvite(userId, inviteId)
	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	ctx.Status(http.StatusOK)
}

// GetInvites godoc
// @Summary Gets all active invites
// @Description Gets all invites that are not expired
// @Param query query GetGroupInvitesDto true "body"
// @Tags Group
// @Security JWT
// @Success 200 {object} []GroupInviteDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/invites [get]
func (controller GroupsController) GetInvites(ctx *gin.Context) {
	var getGroupInvitesDto GetGroupInvitesDto
	if err := Query(ctx, &getGroupInvitesDto); err != nil {
		return
	}

	_, err := controller.AuthGroupMember(ctx, getGroupInvitesDto.GroupID)
	if err != nil {
		return
	}

	invites := controller.Database.GetGroupInvites(getGroupInvitesDto.GroupID)

	inviteDtos := lo.Map(invites, func(invite data.GroupInvite, i int) GroupInviteDto {
		return ToGroupInviteDto(invite, controller.Config)
	})

	ctx.JSON(http.StatusOK, inviteDtos)
}

// Create godoc
// @Summary Create a new Group
// @Description Create a new Group given a `CreateGroupDto`.
// @Param body body CreateGroupDto true "Details of newly created group"
// @Tags Group
// @Security JWT
// @Success 200 {object} GroupSummaryDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/create [post]
func (controller GroupsController) Create(ctx *gin.Context) {
	userId, err := controller.AuthUserId(ctx)
	if err != nil {
		return
	}

	var createGroupDto CreateGroupDto
	if err := Body(ctx, &createGroupDto); err != nil {
		return
	}

	group := data.Group{
		Name:        createGroupDto.Name,
		Description: createGroupDto.Description,
		Owner:       nil,
	}
	err = controller.Database.CreateGroup(&group)

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	groupMember, err := controller.Database.AddUserToGroup(userId, group.ID)

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	group.OwnerID = groupMember.ID
	err = controller.Database.UpdateGroupOwner(group.ID, group.OwnerID)

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	ctx.JSON(http.StatusOK, GroupSummaryDto{
		ID:                  group.ID,
		Name:                group.Name,
		Description:         group.Description,
		UnreadMessagesCount: 0,
		LastSeenMessage:     nil,
	})
}

// GetAll godoc
// @Summary Get all Groups
// @Description Get all the Groups belonging to the current user
// @Security JWT
// @Tags Group
// @Success 200 {object} []GroupSummaryDto
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/all [get]
func (controller GroupsController) GetAll(ctx *gin.Context) {
	userId, err := controller.AuthUserId(ctx)
	if err != nil {
		return
	}

	groups := controller.Database.GetAllGroups(userId)
	groupIds := lo.Map(groups,
		func(grp data.GroupMember, i int) uint { return grp.GroupID })
	lastMessages := controller.Database.GetLastMessagesForGroups(groupIds)
	lastMessagesDtos := lo.MapValues(lastMessages, func(val data.Message, key uint) *MessageDto {
		dto := ToMessageDto(val)
		return &dto
	})
	unreadMessagesCount := controller.Database.GetUnreadMessagesCountForGroups(userId, groupIds)

	dtos := make([]GroupSummaryDto, len(groups))
	for i, groupMember := range groups {
		dtos[i] = GroupSummaryDto{
			ID:                  groupMember.Group.ID,
			Name:                groupMember.Group.Name,
			Description:         groupMember.Group.Description,
			LastSeenMessage:     lastMessagesDtos[groupMember.GroupID],
			UnreadMessagesCount: unreadMessagesCount[groupMember.GroupID],
		}
	}
	ctx.JSON(http.StatusOK, dtos)
}

// JoinByInvite godoc
// @Summary Join a group
// @Description Join a group using this invite link
// @Param        inviteId   path      string  true  "InviteID (UUID)"
// @Tags Group
// @Security JWT
// @Success 200 {object} GroupSummaryDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/join/{inviteId} [get]
func (controller GroupsController) JoinByInvite(ctx *gin.Context) {
	userId, err := controller.AuthUserId(ctx)
	if err != nil {
		return
	}
	var joinGroupInviteDto JoinGroupInviteDto
	if err := Uri(ctx, &joinGroupInviteDto); err != nil {
		return
	}

	// This will definitely pass, since we have a validator checking
	// the UUID format
	inviteId := uuid.MustParse(joinGroupInviteDto.InviteID)

	invite, err := controller.Database.JoinByInvite(userId, inviteId)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage(err.Error()))
		return
	}

	group := controller.Database.GetGroup(invite.GroupID)
	lastMessages := controller.Database.GetLastMessagesForGroups([]uint{group.ID})
	lastMessagesDtos := lo.MapValues(lastMessages, func(val data.Message, key uint) *MessageDto {
		dto := ToMessageDto(val)
		return &dto
	})
	unreadMessagesCount := controller.Database.GetUnreadMessagesCountForGroups(userId, []uint{group.ID})

	dto := GroupSummaryDto{
		ID:                  group.ID,
		Name:                group.Name,
		Description:         group.Description,
		LastSeenMessage:     lastMessagesDtos[group.ID],
		UnreadMessagesCount: unreadMessagesCount[group.ID],
	}

	ctx.JSON(http.StatusOK, dto)
}

func (controller GroupsController) JoinByInviteUserLink(ctx *gin.Context) {
	var joinGroupInviteDto JoinGroupInviteDto
	if err := Uri(ctx, &joinGroupInviteDto); err != nil {
		return
	}

	ctx.Redirect(http.StatusTemporaryRedirect, "planlah://join/"+joinGroupInviteDto.InviteID)
}

// Register the routes for this controller
func (controller GroupsController) Register(router *gin.RouterGroup) {
	group := router.Group("groups")
	group.POST("create", controller.Create)
	group.GET("all", controller.GetAll)
	group.GET("invites", controller.GetInvites)
	group.PUT("invites/invalidate", controller.InvalidateInvite)
	group.POST("invites/create", controller.CreateInvite)
	group.GET("join/:inviteId", controller.JoinByInvite)
}
