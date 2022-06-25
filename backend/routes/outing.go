package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"log"
	"net/http"
	"planlah.sg/backend/data"
	"time"
)

type OutingController struct {
	BaseController
}

type GetOutingsDto struct {
	GroupID uint `form:"groupId" json:"groupId" binding:"required"`
}

type OutingDto struct {
	ID          uint            `json:"id" binding:"required"`
	Name        string          `json:"name" binding:"required"`
	Description string          `json:"description" binding:"required"`
	GroupID     uint            `json:"groupId" binding:"required"`
	Steps       []OutingStepDto `json:"steps" binding:"required"`
	Timing      *OutingTiming   `json:"timing" binding:"required"`
}

type OutingTiming struct {
	Start time.Time `json:"start" binding:"required"`
	End   time.Time `json:"end" binding:"required"`
}

type OutingStepDto struct {
	ID           uint                `json:"id" binding:"required"`
	Name         string              `json:"name" binding:"required"`
	Description  string              `json:"description" binding:"required"`
	WhereName    string              `json:"whereName" binding:"required"`
	WherePoint   string              `json:"wherePoint" binding:"required"`
	When         time.Time           `json:"when" binding:"required"`
	Votes        []OutingStepVoteDto `json:"votes" binding:"required"`
	VoteDeadline time.Time           `json:"voteDeadline" binding:"required"`
}

type OutingStepVoteDto struct {
	Vote bool           `json:"vote" binding:"required"`
	User UserSummaryDto `json:"user" binding:"required"`
}

type CreateOutingDto struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description" binding:"required"`
	GroupID     uint   `json:"groupId" binding:"required"`
}

type CreateOutingStepDto struct {
	OutingID     uint      `json:"outingId" binding:"required"`
	Name         string    `json:"name" binding:"required"`
	Description  string    `json:"description" binding:"required"`
	WhereName    string    `json:"whereName" binding:"required"`
	WherePoint   string    `json:"wherePoint" binding:"required"`
	When         time.Time `json:"when" binding:"required"`
	VoteDeadline time.Time `json:"voteDeadline" binding:"required"`
}

type VoteOutingStepDto struct {
	Vote         bool `json:"vote" binding:"required"`
	OutingStepID uint `json:"outingStepId" binding:"required"`
}

func ToOutingDto(outing data.Outing) OutingDto {
	// TODO: Do the steps and timing
	return OutingDto{
		ID:          outing.ID,
		Name:        outing.Name,
		Description: outing.Description,
		GroupID:     outing.GroupID,
		// TODO: Hardcode this for now
		Steps: []OutingStepDto{
			{
				ID:          123,
				Name:        "Jotham",
				Description: "Dasdasd",
				WhereName:   "Dasda",
				WherePoint:  "Dasdasd",
				When:        time.Now(),
				Votes: []OutingStepVoteDto{
					{
						Vote: true,
						User: UserSummaryDto{
							Username: "What the duck am i doing with my life",
							Name:     "Steve",
						},
					},
				},
				VoteDeadline: time.Now(),
			},
		},
		Timing: &OutingTiming{
			Start: time.Now(),
			End:   time.Now(),
		},
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
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/create [post]
func (controller *OutingController) Create(ctx *gin.Context) {
	var createOutingDto CreateOutingDto

	userId := controller.Auth.AuthenticatedUserId(ctx)

	if err := Body(ctx, &createOutingDto); err != nil {
		return
	}

	if controller.Database.GetGroupMember(userId, createOutingDto.GroupID) == nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("user is not a member of this group"))
		return
	}

	outing := data.Outing{
		GroupID:     createOutingDto.GroupID,
		Name:        createOutingDto.Name,
		Description: createOutingDto.Description,
	}

	err := controller.Database.CreateOuting(&outing)

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	ctx.JSON(http.StatusOK, OutingDto{
		ID:          outing.ID,
		Name:        outing.Name,
		Description: outing.Description,
		GroupID:     outing.GroupID,
		Steps:       []OutingStepDto{},
	})
}

// CreateStep godoc
// @Summary Create an Outing Step
// @Description Create an Outing Step
// @Param body body CreateOutingStepDto true "Details for Outing Step"
// @Tags Outing
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/create_step [post]
func (controller *OutingController) CreateStep(ctx *gin.Context) {
	var getOutingsDto GetOutingsDto

	userId := controller.Auth.AuthenticatedUserId(ctx)

	if err := Query(ctx, &getOutingsDto); err != nil {
		return
	}

	if controller.Database.GetGroupMember(userId, getOutingsDto.GroupID) == nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("user is not a member of this group"))
		return
	}

}

// Get godoc
// @Summary Get all Outings for a Group
// @Description Get all Outings for a Group
// @Param body body GetOutingsDto true "Outing retrieval options"
// @Tags Outing
// @Success 200 {object} []OutingDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/all [get]
func (controller *OutingController) Get(ctx *gin.Context) {
	var getOutingsDto GetOutingsDto

	userId := controller.Auth.AuthenticatedUserId(ctx)

	if err := Query(ctx, &getOutingsDto); err != nil {
		return
	}

	if controller.Database.GetGroupMember(userId, getOutingsDto.GroupID) == nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("user is not a member of this group"))
		return
	}

	outings := controller.Database.GetAllOutings(getOutingsDto.GroupID)

	ctx.JSON(http.StatusOK, ToOutingDtos(outings))
}

// Vote godoc
// @Summary Vote for an Outing Step
// @Description Vote for an Outing Step
// @Param body body VoteOutingStepDto true "Vote for Outing Step"
// @Tags Outing
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/outing/vote [put]
func (controller *OutingController) Vote(ctx *gin.Context) {
	var getOutingsDto GetOutingsDto

	userId := controller.Auth.AuthenticatedUserId(ctx)

	if err := Query(ctx, &getOutingsDto); err != nil {
		return
	}

	if controller.Database.GetGroupMember(userId, getOutingsDto.GroupID) == nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("user is not a member of this group"))
		return
	}

}

// Register the routes for this controller
func (controller *OutingController) Register(router *gin.RouterGroup) {
	group := router.Group("outing")
	group.POST("create", controller.Create)
	group.POST("create_step", controller.CreateStep)
	group.GET("all", controller.Get)
	group.PUT("vote", controller.Vote)
}
