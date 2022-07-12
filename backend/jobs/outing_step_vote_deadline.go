package jobs

import (
	"context"
	"encoding/json"
	"github.com/juju/errors"
	"github.com/samber/lo"
	"github.com/vgarvardt/gue/v3"
	"planlah.sg/backend/data"
	"sort"
)

var VoteDeadlineJobName = "voteDeadlineJob"

type VoteDeadlineJob struct {
	Database *data.Database
}

func NewVoteDeadlineJob(database *data.Database) *VoteDeadlineJob {
	return &VoteDeadlineJob{Database: database}
}

type VoteDeadlineJobArgs struct {
	OutingId uint
}

func StepCollidesWith(step data.OutingStep, test data.OutingStep) bool {
	return step.Start.Before(test.End) && step.End.After(test.Start)
}

func AnyStepsCollidesWith(steps []data.OutingStep, test data.OutingStep) bool {
	return lo.SomeBy(steps, func(step data.OutingStep) bool {
		return StepCollidesWith(step, test)
	})
}

func CollidingOutingSteps(outingSteps []data.OutingStep) [][]data.OutingStep {
	// O(n^3) algo, but not like ppl will have so many OutingSteps
	collidingStepSet := make([][]data.OutingStep, 0)
	for _, step := range outingSteps {
		added := false
		for i, collidingSteps := range collidingStepSet {
			if AnyStepsCollidesWith(collidingSteps, step) {
				collidingStepSet[i] = append(collidingSteps, step)
				added = true
				break
			}
		}
		if !added {
			collidingStepSet = append(collidingStepSet, []data.OutingStep{step})
		}
	}
	return collidingStepSet
}

func checkApproved(outingStep data.OutingStep) bool {
	// check if we can approve
	voteYes := lo.CountBy(outingStep.Votes, func(vote data.OutingStepVote) bool {
		return vote.Vote
	})
	voteNo := len(outingStep.Votes) - voteYes
	return voteYes >= voteNo
}

// TODO need to unit test this!

func (job *VoteDeadlineJob) Run(ctx context.Context, j *gue.Job) error {

	var args VoteDeadlineJobArgs
	err := json.Unmarshal(j.Args, &args)
	if err != nil {
		return errors.Annotate(err, "parse voteDeadlineJob args")
	}

	outing, err := job.Database.GetOutingWithSteps(args.OutingId)
	if err != nil {
		if errors.Is(err, data.EntityNotFound) {
			return errors.Annotate(err, "outing not found")
		}
		return errors.Annotate(err, "outing db err")
	}

	// remove all unapproved steps
	steps := lo.Filter(outing.Steps, func(t data.OutingStep, _ int) bool {
		return checkApproved(t)
	})

	// Sort the outing steps makes it easier to find collisions
	sort.Slice(steps, func(i, j int) bool {
		return steps[i].Start.Before(steps[j].Start)
	})
	collidingSet := CollidingOutingSteps(steps)

	removed := make([]data.OutingStep, 0)

	// remove the conflicts and flatten list
	// first come, first served
	for _, colliding := range collidingSet {
		nonConflicting := make([]data.OutingStep, 0)
		for _, step := range colliding {
			if !AnyStepsCollidesWith(nonConflicting, step) {
				nonConflicting = append(nonConflicting, step)
			} else {
				removed = append(removed, step)
			}
		}
	}

	err = job.Database.DeleteOutingSteps(removed)
	if err != nil {
		return errors.Annotate(err, "delete conflicting outing steps")
	}

	return nil
}
