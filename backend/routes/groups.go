package routes

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/samber/lo"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
	"planlah.sg/backend/utils"
	"time"
)

type GroupsController struct {
	BaseController
	ImageService services.ImageService
}

type CreateGroupDto struct {
	Name        string `form:"name" binding:"required"`
	Description string `form:"description" binding:"required"`
}

type GroupSummaryDto struct {
	ID                  uint        `json:"id" binding:"required"`
	Name                string      `json:"name" binding:"required"`
	ImageLink           string      `json:"imageLink" binding:"required"`
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
	var dto CreateGroupInviteDto
	if Body(ctx, &dto) {
		return
	}

	_, err := controller.AuthGroupMember(ctx, dto.GroupID)
	if err != nil {
		return
	}

	var expiry *time.Time

	switch ExpiryOption(dto.ExpiryOption) {
	case OneHour:
		t := time.Now().In(time.UTC).Add(time.Hour)
		expiry = &t
	case OneDay:
		t := time.Now().In(time.UTC).Add(time.Hour * 24)
		expiry = &t
	case Never:
		expiry = nil
	default:
		// TODO maybe use validation error?
		FailWithMessage(ctx, "invalid `expiryOption`")
		return
	}

	invite := data.GroupInvite{
		Expiry:  expiry,
		GroupID: dto.GroupID,
		Active:  true,
	}

	err = controller.Database.CreateGroupInvite(&invite)

	if err != nil {
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

	var dto InvalidateGroupInviteDto
	if Body(ctx, &dto) {
		return
	}

	// This will definitely pass, since we have a validator checking
	// the UUID format
	inviteId := uuid.MustParse(dto.InviteID)

	err = controller.Database.InvalidateInvite(userId, inviteId)
	if err != nil {
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
	var dto GetGroupInvitesDto
	if Query(ctx, &dto) {
		return
	}

	_, err := controller.AuthGroupMember(ctx, dto.GroupID)
	if err != nil {
		return
	}

	invites, err := controller.Database.GetGroupInvites(dto.GroupID)
	if err != nil {
		return
	}

	inviteDtos := lo.Map(invites, func(invite data.GroupInvite, i int) GroupInviteDto {
		return ToGroupInviteDto(invite, controller.Config)
	})

	ctx.JSON(http.StatusOK, inviteDtos)
}

// Create godoc
// @Summary Create a new Group
// @Description Create a new Group given a `CreateGroupDto`.
// @Param form formData CreateGroupDto true "Details of newly created group"
// @Param        image  formData  file  true  "Group Image"
// @Accept       multipart/form-data
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

	var dto CreateGroupDto
	if Form(ctx, &dto) {
		return
	}

	// maybe only allow upto a certain file size in meta (_ in below line)
	file, _, err := ctx.Request.FormFile("image")

	if err != nil {
		// TODO validation message
		FailWithMessage(ctx, "image file field missing")
		return
	}

	imageUrl, err := controller.ImageService.UploadGroupImage(file)
	if err != nil {
		// TODO how to handle this?
		return
	}

	group := data.Group{
		Name:        dto.Name,
		Description: dto.Description,
		Owner:       nil, // TODO can I auto create Owner when this Group is added?
		ImageLink:   imageUrl,
	}
	err = controller.Database.CreateGroup(&group)

	if err != nil {
		return
	}

	groupMember, err := controller.Database.AddUserToGroup(userId, group.ID)

	if err != nil {
		return
	}

	group.OwnerID = groupMember.ID
	err = controller.Database.UpdateGroupOwner(group.ID, group.OwnerID)

	if err != nil {
		return
	}

	ctx.JSON(http.StatusOK, GroupSummaryDto{
		ID:                  group.ID,
		Name:                group.Name,
		Description:         group.Description,
		UnreadMessagesCount: 0,
		LastSeenMessage:     nil,
		ImageLink:           group.ImageLink,
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

	// TODO clean this up
	groups, err := controller.Database.GetAllGroups(userId)
	groupIds := lo.Map(groups,
		func(grp data.GroupMember, i int) uint { return grp.GroupID })
	lastMessages, err := controller.Database.GetLastMessagesForGroups(groupIds)
	lastMessagesDtos := lo.MapValues(lastMessages, func(val data.Message, key uint) *MessageDto {
		dto := ToMessageDto(val)
		return &dto
	})
	unreadMessagesCount, err := controller.Database.GetUnreadMessagesCountForGroups(userId, groupIds)

	dtos := make([]GroupSummaryDto, len(groups))
	for i, groupMember := range groups {
		dtos[i] = GroupSummaryDto{
			ID:                  groupMember.Group.ID,
			Name:                groupMember.Group.Name,
			Description:         groupMember.Group.Description,
			ImageLink:           groupMember.Group.ImageLink,
			LastSeenMessage:     lastMessagesDtos[groupMember.GroupID],
			UnreadMessagesCount: unreadMessagesCount[groupMember.GroupID],
		}
	}
	ctx.JSON(http.StatusOK, dtos)
}

// JoinByInvite godoc
// @Summary Join a group
// @Description Join a group using invite id
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

	var dto JoinGroupInviteDto
	if Uri(ctx, &dto) {
		return
	}

	// This will definitely pass, since we have a validator checking
	// the UUID format
	inviteId := uuid.MustParse(dto.InviteID)

	invite, err := controller.Database.JoinByInvite(userId, inviteId)
	if err != nil {
		if err == data.UserAlreadyInGroup {
			// TODO handle
		}
		return
	}

	// TODO cleanup
	group, err := controller.Database.GetGroup(invite.GroupID)
	lastMessages, err := controller.Database.GetLastMessagesForGroups([]uint{group.ID})
	lastMessagesDtos := lo.MapValues(lastMessages, func(val data.Message, key uint) *MessageDto {
		dto := ToMessageDto(val)
		return &dto
	})
	unreadMessagesCount, err := controller.Database.GetUnreadMessagesCountForGroups(userId, []uint{group.ID})

	groupDto := GroupSummaryDto{
		ID:                  group.ID,
		Name:                group.Name,
		Description:         group.Description,
		LastSeenMessage:     lastMessagesDtos[group.ID],
		UnreadMessagesCount: unreadMessagesCount[group.ID],
	}

	ctx.JSON(http.StatusOK, groupDto)
}

// JoinByInviteUserLink godoc
// @Summary Join a group, the User version
// @Description Join a group using this invite link
// @Param        inviteId   path      string  true  "InviteID (UUID)"
// @Tags Group
// @Security JWT
// @Success 307
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router join/{inviteId} [get]
func (controller GroupsController) JoinByInviteUserLink(ctx *gin.Context) {
	var joinGroupInviteDto JoinGroupInviteDto
	if Uri(ctx, &joinGroupInviteDto) {
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
