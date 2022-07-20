package routes

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/juju/errors"
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
	IsDM                bool        `json:"isDm" binding:"required"`
}

type GroupInviteDto struct {
	ID      string     `json:"id" binding:"required,uuid"`
	GroupID uint       `json:"groupId" binding:"required"`
	Url     string     `json:"url" binding:"required"`
	Expiry  *time.Time `json:"expiry"` // TODO add comment about null expiry
}

type JioToGroupDto struct {
	UserID  uint `json:"userId" binding:"required"`
	GroupID uint `json:"groupId" binding:"required"`
}

type LeaveGroupDto struct {
	UserID  uint `json:"userId" binding:"required"`
	GroupID uint `json:"groupId" binding:"required"`
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

type GroupRefDto struct {
	GroupID uint `form:"groupId" json:"groupId" binding:"required"`
}

type JioFriendsDto struct {
	Page    data.Pagination
	GroupID uint `form:"groupId" json:"groupId" binding:"required"`
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

func ToGroupSummaryDto(grp data.GroupInfo) GroupSummaryDto {
	var lastMsgDtoRef *MessageDto
	if grp.LastMessage != nil {
		lastMsgDto := ToMessageDto(*grp.LastMessage)
		lastMsgDtoRef = &lastMsgDto
	}

	return GroupSummaryDto{
		ID:                  grp.ID,
		Name:                grp.Name,
		Description:         grp.Description,
		ImageLink:           grp.ImageLink,
		LastSeenMessage:     lastMsgDtoRef,
		UnreadMessagesCount: grp.UnreadMessageCount,
		IsDM:                grp.IsDM,
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
// @Failure 401 {object} services.AuthError
// @Router /api/groups/invites/create [post]
func (ctr *GroupsController) CreateInvite(ctx *gin.Context) {
	var dto CreateGroupInviteDto
	if Body(ctx, &dto) {
		return
	}

	member := ctr.AuthGroupMember(ctx, dto.GroupID)
	if member == nil {
		return
	}

	// not available for IsDM=true
	group, err := ctr.Database.GetGroup(member.UserID, member.GroupID)
	if group.IsDM {
		FailWithMessage(ctx, "cannot create invites for dm groups")
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
		FailWithMessage(ctx, "invalid `expiryOption`")
		return
	}

	invite := data.GroupInvite{
		Expiry:  expiry,
		GroupID: dto.GroupID,
		Active:  true,
	}

	err = ctr.Database.CreateGroupInvite(&invite)

	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToGroupInviteDto(invite, ctr.Config))
}

// Jio godoc
// @Summary Invite a friend
// @Description Invite a friend over to this group. The user must be a friend of the current user.
// @Description If this group is a DM group, this upgrades the group to a normal group.
// @Param body body JioToGroupDto true "Details of Jio request"
// @Tags Group
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/groups/jio [post]
func (ctr *GroupsController) Jio(ctx *gin.Context) {
	var dto JioToGroupDto
	if Body(ctx, &dto) {
		return
	}

	member := ctr.AuthGroupMember(ctx, dto.GroupID)
	if member == nil {
		return
	}

	// not available for IsDM=true
	group, err := ctr.Database.GetGroup(member.UserID, member.GroupID)
	if group.IsDM {
		FailWithMessage(ctx, "cannot jio for dm groups")
		return
	}

	isFriend, err := ctr.Database.IsFriend(member.UserID, dto.UserID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}
	if !isFriend {
		FailWithMessage(ctx, "users are not friends")
		return
	}

	_, err = ctr.Database.AddUserToGroup(dto.UserID, dto.GroupID)
	if err != nil {
		if errors.Is(err, data.UserAlreadyInGroup) {
			FailWithMessage(ctx, "user is already in group")
			return
		}
		handleDbError(ctx, err)
		return
	}

	// Send notification to other group members + this user
	err = ctr.Hub.SendToGroup(dto.GroupID, services.NewGroupUpdate(dto.GroupID))
	handleHubError(ctr.Logger, err)
	// Send notification to entering User
	err = ctr.Hub.SendToUser(dto.UserID, services.NewGroupsUpdate())
	handleHubError(ctr.Logger, err)

	ctx.Status(http.StatusOK)
}

// Leave godoc
// @Summary Leave a group
// @Description The user leaves a specified group chat.
// @Description If this group is a DM group, this does nothing.
// @Param body body LeaveGroupDto true "Details of Leave request"
// @Tags Group
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/groups/leave [post]
func (ctr *GroupsController) Leave(ctx *gin.Context) {
	var dto LeaveGroupDto
	if Body(ctx, &dto) {
		return
	}

	member := ctr.AuthGroupMember(ctx, dto.GroupID)
	if member == nil {
		return
	}

	// not available for IsDM=true
	group, err := ctr.Database.GetGroup(member.UserID, member.GroupID)
	if group.IsDM {
		FailWithMessage(ctx, "cannot leave a dm group")
		return
	}

	err = ctr.Database.RemoveUserFromGroup(dto.UserID, dto.GroupID)
	if err != nil {
		if errors.Is(err, data.UserAlreadyInGroup) {
			FailWithMessage(ctx, "user is already in group")
			return
		}
		handleDbError(ctx, err)
		return
	}

	// Send notification to other group members
	err = ctr.Hub.SendToGroup(dto.GroupID, services.NewGroupUpdate(dto.GroupID))
	handleHubError(ctr.Logger, err)
	// Send notification to leaving User
	err = ctr.Hub.SendToUser(dto.UserID, services.NewGroupsUpdate())
	handleHubError(ctr.Logger, err)

	ctx.Status(http.StatusOK)
}

// InvalidateInvite godoc
// @Summary Invalidates an invitation
// @Description Invalidates an invitation so that no one else can join
// @Param body body InvalidateGroupInviteDto true "Details of invite to invalidate"
// @Tags Group
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/groups/invites/invalidate [put]
func (ctr *GroupsController) InvalidateInvite(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto InvalidateGroupInviteDto
	if Body(ctx, &dto) {
		return
	}

	// This will definitely pass, since we have a validator checking
	// the UUID format
	inviteId := uuid.MustParse(dto.InviteID)

	err := ctr.Database.InvalidateInvite(userId, inviteId)
	if err != nil {
		handleDbError(ctx, err)
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
// @Failure 401 {object} services.AuthError
// @Router /api/groups/invites [get]
func (ctr *GroupsController) GetInvites(ctx *gin.Context) {
	var dto GetGroupInvitesDto
	if Query(ctx, &dto) {
		return
	}

	if ctr.AuthGroupMember(ctx, dto.GroupID) == nil {
		return
	}

	invites, err := ctr.Database.GetGroupInvites(dto.GroupID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	inviteDtos := lo.Map(invites, func(invite data.GroupInvite, i int) GroupInviteDto {
		return ToGroupInviteDto(invite, ctr.Config)
	})

	ctx.JSON(http.StatusOK, inviteDtos)
}

// CreateDM godoc
// @Summary [UNIMPL] Create a new DM group (one-to-one).
// @Description Create a new DM group with a friend. The user must be a friend of this user. If a DM group already exists, that is returned.
// @Param body body UserRefDto true "Reference to friend to create a DM channel for"
// @Tags Group
// @Security JWT
// @Success 200 {object} GroupSummaryDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/groups/create_dm [post]
func (ctr *GroupsController) CreateDM(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto UserRefDto
	if Body(ctx, &dto) {
		return
	}

	groupInfo, err := ctr.Database.GetDMGroup(userId, dto.ID)

	if err != nil && !errors.Is(err, data.EntityNotFound) {
		handleDbError(ctx, err)
		return
	}

	if err == nil {
		ctx.JSON(http.StatusOK, ToGroupSummaryDto(groupInfo))
		return
	}

	grp, err := ctr.Database.CreateDMGroup(userId, dto.ID)
	if err != nil {
		if errors.Is(err, data.NotFriend) {
			FailWithMessage(ctx, "user is not friend of this user")
			return
		}
		if errors.Is(err, data.DMAlreadyExists) {
			FailWithMessage(ctx, "dm exists between the users")
			return
		}
		handleDbError(ctx, err)
		return
	}
	groupInfo, err = ctr.Database.GetGroup(userId, grp.ID)
	if err != nil { // this group is always found
		handleDbError(ctx, err)
		return
	}

	// Send notification to two group members that there is a new group
	err = ctr.Hub.SendToGroup(groupInfo.ID, services.NewGroupsUpdate())
	handleHubError(ctr.Logger, err)

	ctx.JSON(http.StatusOK, ToGroupSummaryDto(groupInfo))
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
// @Failure 401 {object} services.AuthError
// @Router /api/groups/create [post]
func (ctr *GroupsController) Create(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto CreateGroupDto
	if Form(ctx, &dto) {
		return
	}

	// maybe only allow upto a certain file size in meta (_ in below line)
	file, _, err := ctx.Request.FormFile("image")
	if err != nil {
		FailWithMessage(ctx, "image file field missing")
		return
	}

	imageUrl, err := ctr.ImageService.UploadGroupImage(file)
	if err != nil {
		handleImageUploadError(ctx, err)
		return
	}

	group := data.Group{
		Name:        dto.Name,
		Description: dto.Description,
		Owner:       nil, // TODO can I auto create Owner when this Group is added?
		ImageLink:   imageUrl,
		IsDM:        false,
	}
	err = ctr.Database.CreateGroup(&group)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	groupMember, err := ctr.Database.AddUserToGroup(userId, group.ID)

	if err != nil {
		if errors.Is(err, data.UserAlreadyInGroup) {
			ctr.Logger.Fatal("IMPOSSIBLE: user is already member of just-created group")
			return
		}
		handleDbError(ctx, err)
		return
	}

	group.OwnerID = groupMember.ID
	err = ctr.Database.UpdateGroupOwner(group.ID, group.OwnerID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	// Send notification to the only group member that there is a new group
	err = ctr.Hub.SendToUser(groupMember.UserID, services.NewGroupsUpdate())
	handleHubError(ctr.Logger, err)

	ctx.JSON(http.StatusOK, ToGroupSummaryDto(data.GroupInfo{Group: group}))
}

// GetAll godoc
// @Summary Get all Groups
// @Description Get all the Groups belonging to the current user
// @Security JWT
// @Tags Group
// @Success 200 {object} []GroupSummaryDto
// @Failure 401 {object} services.AuthError
// @Router /api/groups/all [get]
func (ctr *GroupsController) GetAll(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	groups, err := ctr.Database.GetAllGroups(userId)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	dtos := lo.Map(groups, func(grp data.GroupInfo, _ int) GroupSummaryDto {
		return ToGroupSummaryDto(grp)
	})

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
// @Failure 401 {object} services.AuthError
// @Router /api/groups/join/{inviteId} [get]
func (ctr *GroupsController) JoinByInvite(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto JoinGroupInviteDto
	if Uri(ctx, &dto) {
		return
	}

	// This will definitely pass, since we have a validator checking
	// the UUID format
	inviteId := uuid.MustParse(dto.InviteID)

	invite, err := ctr.Database.JoinByInvite(userId, inviteId)
	if err != nil {
		if errors.Is(err, data.EntityNotFound) {
			FailWithMessage(ctx, "invite does not exist")
			return
		}
		if errors.Is(err, data.UserAlreadyInGroup) {
			FailWithMessage(ctx, "user is already in group")
			return
		}
		handleDbError(ctx, err)
		return
	}

	group, err := ctr.Database.GetGroup(userId, invite.GroupID)
	if err != nil { // this group is always found
		handleDbError(ctx, err)
		return
	}

	// Send notification to other group members + this user that this user has joined
	err = ctr.Hub.SendToGroup(group.ID, services.NewGroupUpdate(group.ID))
	handleHubError(ctr.Logger, err)
	// Send notification to entering User
	err = ctr.Hub.SendToUser(userId, services.NewGroupsUpdate())
	handleHubError(ctr.Logger, err)

	ctx.JSON(http.StatusOK, ToGroupSummaryDto(group))
}

// JoinByInviteUserLink godoc
// @Summary Join a group, the User version
// @Description Join a group using this invite link
// @Param        inviteId   path      string  true  "InviteID (UUID)"
// @Tags Group
// @Security JWT
// @Success 307
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /join/{inviteId} [get]
func (ctr *GroupsController) JoinByInviteUserLink(ctx *gin.Context) {
	var dto JoinGroupInviteDto
	if Uri(ctx, &dto) {
		return
	}

	ctx.Redirect(http.StatusTemporaryRedirect, "planlah://join/"+dto.InviteID)
}

// GetGroupMembers godoc
// @Summary Gets all members in a group
// @Description Gets all members in a group
// @Param query query GroupRefDto true "body"
// @Tags Group
// @Security JWT
// @Success 200 {object} []UserSummaryDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/groups/get_members [get]
func (ctr *GroupsController) GetGroupMembers(ctx *gin.Context) {
	var dto GroupRefDto
	if Query(ctx, &dto) {
		return
	}

	if ctr.AuthGroupMember(ctx, dto.GroupID) == nil {
		return
	}

	users, err := ctr.Database.GetAllGroupMembers(dto.GroupID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	userDtos := lo.Map(users, func(user data.User, i int) UserSummaryDto {
		return ToUserSummaryDto(user)
	})

	ctx.JSON(http.StatusOK, userDtos)
}

// GetFriendsToJio godoc
// @Summary Gets all friends who are not in a group
// @Description Gets all friends who are not in a group
// @Param query query JioFriendsDto true "body"
// @Tags Group
// @Security JWT
// @Success 200 {object} []UserSummaryDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/groups/get_friends_to_jio [get]
func (ctr *GroupsController) GetFriendsToJio(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto JioFriendsDto
	if Query(ctx, &dto) {
		return
	}

	if ctr.AuthGroupMember(ctx, dto.GroupID) == nil {
		return
	}

	users, err := ctr.Database.GetFriendsToJio(userId, dto.GroupID, dto.Page)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	userDtos := lo.Map(users, func(user data.User, i int) UserSummaryDto {
		return ToUserSummaryDto(user)
	})

	ctx.JSON(http.StatusOK, userDtos)
}

// Register the routes for this controller
func (ctr *GroupsController) Register(router *gin.RouterGroup) {
	group := router.Group("groups")
	group.POST("create", ctr.Create)
	group.POST("create_dm", ctr.CreateDM)
	group.GET("all", ctr.GetAll)
	group.GET("invites", ctr.GetInvites)
	group.POST("jio", ctr.Jio)
	group.POST("leave", ctr.Leave)
	group.PUT("invites/invalidate", ctr.InvalidateInvite)
	group.POST("invites/create", ctr.CreateInvite)
	group.GET("join/:inviteId", ctr.JoinByInvite)
	group.GET("get_members", ctr.GetGroupMembers)
	group.GET("get_friends_to_jio", ctr.GetFriendsToJio)
}
