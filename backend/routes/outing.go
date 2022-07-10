package routes

import (
	"fmt"
	"github.com/juju/errors"
	"net/http"
	"planlah.sg/backend/jobs"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"planlah.sg/backend/data"
)

type OutingController struct {
	BaseController
	JobRunner *jobs.Runner
}

type OutingDto struct {
	ID          uint      `json:"id" binding:"required"`
	Name        string    `json:"name" binding:"required"`
	Description string    `json:"description" binding:"required"`
	GroupID     uint      `json:"groupId" binding:"required"`
	Start       time.Time `json:"start" binding:"required"`
	End         time.Time `json:"end" binding:"required"`
	// Array of Conflicting Steps (in terms of start-end conflicts).
	// If there is no conflict for a step, then it becomes an array of
	// that singular step among these arrays of steps.
	// See: https://github.com/Enigmatrix/planlah/issues/55#issuecomment-1179307936
	Steps [][]OutingStepDto `json:"steps" binding:"required"`
}

type OutingStepDto struct {
	ID           uint                `json:"id" binding:"required"`
	Description  string              `json:"description" binding:"required"`
	Approved     bool                `json:"approved" binding:"required"`
	Place        PlaceDto            `json:"place" binding:"required"`
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
	End         time.Time `json:"end" binding:"required,gtfield=Start"`
}

type CreateOutingStepDto struct {
	OutingID     uint      `json:"outingId" binding:"required"`
	PlaceID      uint      `json:"placeId" binding:"required"`
	Description  string    `json:"description" binding:"required"`
	Start        time.Time `json:"start" binding:"required"`
	End          time.Time `json:"end" binding:"required,gtfield=Start"`
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
		Description:  outingStep.Description,
		Approved:     outingStep.Approved,
		Place:        ToPlaceDto(outingStep.Place),
		Start:        outingStep.Start,
		End:          outingStep.End,
		Votes:        ToOutingStepVoteDtos(outingStep.Votes),
		VoteDeadline: outingStep.VoteDeadline,
	}
}

func ToOutingStepDtos(outingSteps []data.OutingStep) [][]OutingStepDto {
	colliding := jobs.CollidingOutingSteps(outingSteps)

	return lo.Map(colliding, func(collideSet []data.OutingStep, _ int) []OutingStepDto {
		return lo.Map(outingSteps, func(outingStep data.OutingStep, _ int) OutingStepDto {
			return ToOutingStepDto(outingStep)
		})
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

// CreateOuting godoc
// @Summary Create a new Outing
// @Description Create a new Outing plan
// @Param body body CreateOutingDto true "Initial details of Outing"
// @Tags Outing
// @Security JWT
// @Success 200 {object} OutingDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/outing/create [post]
func (ctr *OutingController) CreateOuting(ctx *gin.Context) {
	var dto CreateOutingDto
	if Body(ctx, &dto) {
		return
	}

	if ctr.AuthGroupMember(ctx, dto.GroupID) == nil {
		return
	}

	activeOuting, err := ctr.Database.GetActiveOuting(dto.GroupID)
	if activeOuting != nil && time.Now().In(time.UTC).Before(activeOuting.End) {
		FailWithMessage(ctx, "group already has an active outing")
		return
	}
	if err != nil {
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

	err = ctr.Database.CreateOuting(&outing)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	err = ctr.Database.UpdateActiveOuting(dto.GroupID, outing.ID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToOutingDto(outing))
}

// CreateStep godoc
// @Summary CreateOuting an Outing Step
// @Description CreateOuting an Outing Step
// @Param body body CreateOutingStepDto true "Details for Outing Step"
// @Tags Outing
// @Security JWT
// @Success 200 {object} OutingStepDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/outing/create_step [post]
func (ctr *OutingController) CreateStep(ctx *gin.Context) {
	var dto CreateOutingStepDto
	if Body(ctx, &dto) {
		return
	}

	outingId := dto.OutingID
	outing, err := ctr.Database.GetOuting(outingId)
	if errors.Is(err, data.EntityNotFound) {
		FailWithMessage(ctx, "outing not found")
		return
	} else if err != nil {
		handleDbError(ctx, err)
		return
	}

	if ctr.AuthGroupMember(ctx, outing.GroupID) == nil {
		return
	}

	if outing.Start.After(dto.Start) || outing.End.Before(dto.End) {
		FailWithMessage(ctx, "outing step has invalid start and end (not within outing)")
		return
	}

	// round the time to nearest minute
	dto.VoteDeadline = dto.VoteDeadline.Round(time.Minute)

	if time.Now().After(dto.VoteDeadline) || outing.Start.After(dto.VoteDeadline) {
		FailWithMessage(ctx, fmt.Sprintf("outing step has invalid voteDeadline (%s)", dto.VoteDeadline))
		return
	}

	outingStep := data.OutingStep{
		OutingID:     outingId,
		Description:  dto.Description,
		PlaceID:      dto.PlaceID,
		Start:        dto.Start,
		Approved:     false,
		End:          dto.End,
		VoteDeadline: dto.VoteDeadline,
	}

	err = ctr.Database.CreateOutingStep(&outingStep)
	if err != nil {
		if errors.Is(err, data.EntityNotFound) {
			FailWithMessage(ctx, "place not found")
			return
		}
		handleDbError(ctx, err)
		return
	}

	err = ctr.JobRunner.QueueVoteDeadlineJob(outingStep.VoteDeadline, jobs.VoteDeadlineJobArgs{
		OutingStepId: outingStep.ID,
		OutingId:     outingStep.OutingID,
	})
	if err != nil {
		// TODO how to handle
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
// @Failure 401 {object} services.AuthError
// @Router /api/outing/all [get]
func (ctr *OutingController) Get(ctx *gin.Context) {
	var dto GetOutingsDto

	if Query(ctx, &dto) {
		return
	}

	groupId := dto.GroupID
	if ctr.AuthGroupMember(ctx, groupId) == nil {
		return
	}

	outings, err := ctr.Database.GetAllOutings(groupId)
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
// @Failure 401 {object} services.AuthError
// @Router /api/outing/active [get]
func (ctr *OutingController) GetActive(ctx *gin.Context) {
	var dto GetActiveOutingDto
	if Query(ctx, &dto) {
		return
	}

	groupId := dto.GroupID
	if ctr.AuthGroupMember(ctx, groupId) == nil {
		return
	}

	outing, err := ctr.Database.GetActiveOuting(groupId)
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
// @Failure 401 {object} services.AuthError
// @Router /api/outing/vote [put]
func (ctr *OutingController) Vote(ctx *gin.Context) {
	var dto VoteOutingStepDto

	if Body(ctx, &dto) {
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

	outingStepVote := data.OutingStepVote{
		GroupMemberID: grpMember.ID,
		OutingStepID:  dto.OutingStepID,
		Vote:          *dto.Vote,
		VotedAt:       time.Now().In(time.UTC),
	}

	err = ctr.Database.UpsertOutingStepVote(&outingStepVote)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
}

// Register the routes for this controller
func (ctr *OutingController) Register(router *gin.RouterGroup) {
	group := router.Group("outing")
	group.POST("create", ctr.CreateOuting)
	group.POST("create_step", ctr.CreateStep)
	group.GET("all", ctr.Get)
	group.GET("active", ctr.GetActive)
	group.PUT("vote", ctr.Vote)
}
