package routes

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"planlah.sg/backend/data"
)

type OutingController struct {
	BaseController
}

type OutingDto struct {
	ID          uint            `json:"id" binding:"required"`
	Name        string          `json:"name" binding:"required"`
	Description string          `json:"description" binding:"required"`
	GroupID     uint            `json:"groupId" binding:"required"`
	Start       time.Time       `json:"start" binding:"required"`
	End         time.Time       `json:"end" binding:"required"`
	Steps       []OutingStepDto `json:"steps" binding:"required"`
}

type OutingStepDto struct {
	ID           uint                `json:"id" binding:"required"`
	Name         string              `json:"name" binding:"required"`
	Description  string              `json:"description" binding:"required"`
	WhereName    string              `json:"whereName" binding:"required"`
	WherePoint   string              `json:"wherePoint" binding:"required"`
	Start        time.Time           `json:"start" binding:"required"`
	End          time.Time           `json:"end" binding:"required"`
	Votes        []OutingStepVoteDto `json:"votes" binding:"required"`
	VoteDeadline time.Time           `json:"voteDeadline" binding:"required"`
}

type OutingStepVoteDto struct {
	Vote *bool          `json:"vote" binding:"required"`
	User UserSummaryDto `json:"user" binding:"required"`
}

type CreateOutingDto struct {
	Name        string    `json:"name" binding:"required"`
	Description string    `json:"description" binding:"required"`
	GroupID     uint      `json:"groupId" binding:"required"`
	Start       time.Time `json:"start" binding:"required"`
	End         time.Time `json:"end" binding:"required"`
}

type CreateOutingStepDto struct {
	OutingID     uint      `json:"outingId" binding:"required"`
	Name         string    `json:"name" binding:"required"`
	Description  string    `json:"description" binding:"required"`
	WhereName    string    `json:"whereName" binding:"required"`
	WherePoint   string    `json:"wherePoint" binding:"required"`
	Start        time.Time `json:"start" binding:"required"`
	End          time.Time `json:"end" binding:"required"`
	VoteDeadline time.Time `json:"voteDeadline" binding:"required"`
}

type GetOutingsDto struct {
	GroupID uint `form:"groupId" json:"groupId" binding:"required"`
}

type GetActiveOutingDto struct {
	GroupID uint `form:"groupId" json:"groupId" binding:"required"`
}

type VoteOutingStepDto struct {
	Vote         *bool `json:"vote" binding:"required"`
	OutingStepID uint  `json:"outingStepId" binding:"required"`
}

func ToOutingStepVoteDto(outingStepVote data.OutingStepVote) OutingStepVoteDto {
	return OutingStepVoteDto{
		Vote: &outingStepVote.Vote,
		User: ToUserSummaryDto(*outingStepVote.GroupMember.User),
	}
}

func ToOutingStepVoteDtos(outingStepVotes []data.OutingStepVote) []OutingStepVoteDto {
	return lo.Map(outingStepVotes, func(outingStepVote data.OutingStepVote, _ int) OutingStepVoteDto {
		return ToOutingStepVoteDto(outingStepVote)
	})
}

func ToOutingStepDto(outingStep data.OutingStep) OutingStepDto {
	return OutingStepDto{
		ID:           outingStep.ID,
		Name:         outingStep.Name,
		Description:  outingStep.Description,
		WhereName:    outingStep.WhereName,
		WherePoint:   outingStep.WherePoint,
		Start:        outingStep.Start,
		End:          outingStep.End,
		Votes:        ToOutingStepVoteDtos(outingStep.Votes),
		VoteDeadline: outingStep.VoteDeadline,
	}
}

func ToOutingStepDtos(outingSteps []data.OutingStep) []OutingStepDto {
	return lo.Map(outingSteps, func(outingStep data.OutingStep, _ int) OutingStepDto {
		return ToOutingStepDto(outingStep)
	})
}

func ToOutingDto(outing data.Outing) OutingDto {
	return OutingDto{
		ID:          outing.ID,
		Name:        outing.Name,
		Description: outing.Description,
		GroupID:     outing.GroupID,
		Start:       outing.Start,
		End:         outing.End,
		Steps:       ToOutingStepDtos(outing.Steps),
	}
}

func ToOutingDtos(outings []data.Outing) []OutingDto {
	return lo.Map(outings, func(outing data.Outing, _ int) OutingDto {
		return ToOutingDto(outing)
	})
}

// Create godoc
// @Summary Create a new Outing
// @Description Create a new Outing plan
// @Param body body CreateOutingDto true "Initial details of Outing"
// @Tags Outing
// @Security JWT
// @Success 200 {object} OutingDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/create [post]
func (controller *OutingController) Create(ctx *gin.Context) {
	var dto CreateOutingDto
	if Body(ctx, &dto) {
		return
	}

	if controller.AuthGroupMember(ctx, dto.GroupID) == nil {
		return
	}

	activeOuting, err := controller.Database.GetActiveOuting(dto.GroupID)
	if err == nil && time.Now().In(time.UTC).Before(activeOuting.End) {
		FailWithMessage(ctx, "group already has an active outing")
		return
	} else if err != nil {
		handleDbError(ctx, err)
		return
	}

	// round down start time to nearest day
	startTime := dto.Start
	startDate := time.Date(startTime.Year(), startTime.Month(), startTime.Day(), 0, 0, 0, 0, startTime.Location())

	// round up end time to nearest day
	endTime := dto.End
	endDate := time.Date(endTime.Year(), endTime.Month(), endTime.Day()+1, 0, 0, 0, 0, endTime.Location())

	outing := data.Outing{
		GroupID:     dto.GroupID,
		Name:        dto.Name,
		Description: dto.Description,
		Start:       startDate,
		End:         endDate,
	}

	err = controller.Database.CreateOuting(&outing)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	err = controller.Database.UpdateActiveOuting(dto.GroupID, outing.ID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToOutingDto(outing))
}

// CreateStep godoc
// @Summary Create an Outing Step
// @Description Create an Outing Step
// @Param body body CreateOutingStepDto true "Details for Outing Step"
// @Tags Outing
// @Security JWT
// @Success 200 {object} OutingStepDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/create_step [post]
func (controller *OutingController) CreateStep(ctx *gin.Context) {
	var dto CreateOutingStepDto
	if Body(ctx, &dto) {
		return
	}

	outingId := dto.OutingID
	outing, err := controller.Database.GetOuting(outingId)
	if err == data.EntityNotFound {
		FailWithMessage(ctx, "outing not found")
		return
	} else if err != nil {
		handleDbError(ctx, err)
		return
	}

	if controller.AuthGroupMember(ctx, outing.GroupID) == nil {
		return
	}

	outingStep := data.OutingStep{
		OutingID:     outingId,
		Name:         dto.Name,
		Description:  dto.Description,
		WhereName:    dto.WhereName,
		WherePoint:   dto.WherePoint,
		Start:        dto.Start,
		End:          dto.End,
		VoteDeadline: dto.VoteDeadline,
	}

	err = controller.Database.CreateOutingStep(&outingStep)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToOutingStepDto(outingStep))
}

// Get godoc
// @Summary Get all Outings for a Group
// @Description Get all Outings for a Group
// @Param query query GetOutingsDto true "Outing retrieval options"
// @Tags Outing
// @Security JWT
// @Success 200 {object} []OutingDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/all [get]
func (controller *OutingController) Get(ctx *gin.Context) {
	var dto GetOutingsDto

	if Query(ctx, &dto) {
		return
	}

	groupId := dto.GroupID
	if controller.AuthGroupMember(ctx, groupId) == nil {
		return
	}

	outings, err := controller.Database.GetAllOutings(groupId)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToOutingDtos(outings))
}

// GetActive godoc
// @Summary Gets the active Outing for a Group
// @Description Gets the active Outing for a Group
// @Param query query GetActiveOutingDto true "Outing retrieval options"
// @Tags Outing
// @Security JWT
// @Success 200
// @Success 200 {object} OutingDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/active [get]
func (controller *OutingController) GetActive(ctx *gin.Context) {
	var dto GetActiveOutingDto
	if Query(ctx, &dto) {
		return
	}

	groupId := dto.GroupID
	if controller.AuthGroupMember(ctx, groupId) == nil {
		return
	}

	outing, err := controller.Database.GetActiveOuting(groupId)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	if outing == nil {
		ctx.JSON(http.StatusOK, nil)
	} else {
		ctx.JSON(http.StatusOK, ToOutingDto(*outing))
	}
}

// Vote godoc
// @Summary Vote for an Outing Step
// @Description Vote for an Outing Step
// @Param body body VoteOutingStepDto true "Vote for Outing Step"
// @Tags Outing
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/vote [put]
func (controller *OutingController) Vote(ctx *gin.Context) {
	var dto VoteOutingStepDto

	if Body(ctx, &dto) {
		return
	}

	o, err := controller.Database.GetOutingAndGroupForOutingStep(dto.OutingStepID)
	if err == data.EntityNotFound {
		FailWithMessage(ctx, "outing step not found")
		return
	} else if err != nil {
		handleDbError(ctx, err)
		return
	}

	grpMember := controller.AuthGroupMember(ctx, o.GroupID)
	if grpMember == nil {
		return
	}

	outingStepVote := data.OutingStepVote{
		GroupMemberID: grpMember.ID,
		OutingStepID:  dto.OutingStepID,
		Vote:          *dto.Vote,
		VotedAt:       time.Now().In(time.UTC),
	}

	err = controller.Database.UpsertOutingStepVote(&outingStepVote)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
}

// Register the routes for this controller
func (controller *OutingController) Register(router *gin.RouterGroup) {
	group := router.Group("outing")
	group.POST("create", controller.Create)
	group.POST("create_step", controller.CreateStep)
	group.GET("all", controller.Get)
	group.GET("active", controller.GetActive)
	group.PUT("vote", controller.Vote)
}
