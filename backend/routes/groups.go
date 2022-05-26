package routes

import (
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
)

type GroupsController struct {
	Database *data.Database
	Auth     *services.AuthService
}

type CreateGroupDto struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description" binding:"required"`
}

type GroupDto struct {
	ID           uint             `json:"name" binding:"required"`
	Name         string           `json:"name" binding:"required"`
	Description  string           `json:"description" binding:"required"`
	GroupMembers []UserSummaryDto `json:"group_members" binding:"required"`
	Owner        *UserSummaryDto  `json:"owner" binding:"required"`
}

// Create godoc
// @Summary Create a new Group
// @Description Create a new Group given a `CreateGroupDto`.
// @Param body body CreateGroupDto true "Details of newly created group"
// @Tags Group
// @Security JWT
// @Success 200 {object} GroupDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/create [post]
func (controller GroupsController) Create(ctx *gin.Context) {
	userId := controller.Auth.AuthenticatedUserId(ctx)

	var createGroupDto CreateGroupDto
	if err := Body(ctx, &createGroupDto); err != nil {
		return
	}

	group := data.Group{
		Name:        createGroupDto.Name,
		Description: createGroupDto.Description,
		Owner:       nil,
	}
	err := controller.Database.CreateGroup(&group)

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	groupMember := data.GroupMember{
		UserID:  userId,
		GroupID: group.ID,
	}
	err = controller.Database.CreateGroupMember(&groupMember)

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

	user := controller.Database.GetUser(userId)

	ctx.JSON(http.StatusOK, GroupDto{
		ID:           group.ID,
		Name:         group.Name,
		Description:  group.Description,
		GroupMembers: []UserSummaryDto{},
		Owner: &UserSummaryDto{
			Nickname: user.Nickname,
			Name:     user.Name,
		},
	})
}

// GetAll godoc
// @Summary Get all Groups
// @Description Get all the Groups belonging to the current user
// @Security JWT
// @Tags Group
// @Success 200 {object} []GroupDto
// @Failure 401 {object} ErrorMessage
// @Router /api/groups/all [get]
func (controller GroupsController) GetAll(ctx *gin.Context) {
	userId := controller.Auth.AuthenticatedUserId(ctx)
	print(userId)
	// print(controller.Database.GetAllGroups(userId))
}

// Register the routes for this controller
func (controller GroupsController) Register(router *gin.RouterGroup) {
	group := router.Group("groups")
	group.POST("create", controller.Create)
	group.GET("all", controller.GetAll)
}
