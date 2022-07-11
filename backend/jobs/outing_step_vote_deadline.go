package jobs

import (
	"context"
	"encoding/json"
	"github.com/juju/errors"
	"github.com/samber/lo"
	"github.com/vgarvardt/gue/v3"
	"planlah.sg/backend/data"
)

var VoteDeadlineJobName = "voteDeadlineJob"

type VoteDeadlineJob struct {
	Database *data.Database
}

type VoteDeadlineJobArgs struct {
	OutingStepId uint
	OutingId     uint
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
	allSteps := make([][]data.OutingStep, 0)
	for _, step := range outingSteps {
		added := false
		for _, existing := range allSteps {
			if AnyStepsCollidesWith(existing, step) {
				existing = append(existing, step)
				added = true
				break
			}
		}
		if !added {
			allSteps = append(allSteps, []data.OutingStep{step})
		}
	}
	return allSteps
}

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

	colliding := CollidingOutingSteps(outing.Steps)

	collidingSet, found := lo.Find(colliding, func(collidingSet []data.OutingStep) bool {
		return lo.SomeBy(collidingSet, func(outingStep data.OutingStep) bool {
			return outingStep.ID == args.OutingStepId
		})
	})
	if !found {
		return errors.Annotate(err, "outingStep not found in colliding")
	}

	outingStep, found := lo.Find(collidingSet, func(outingStep data.OutingStep) bool {
		return outingStep.ID == args.OutingStepId
	})
	if !found {
		return errors.Annotate(err, "outingStep not found in collidingSet")
	}

	// already approved, ignore this
	if outingStep.Approved {
		return nil
	}

	// check if we can approve
	voteYes := lo.CountBy(outingStep.Votes, func(vote data.OutingStepVote) bool {
		return vote.Vote
	})
	voteNo := len(outingStep.Votes) - voteYes

	// approve if voteYes >= voteNo
	// else we just delete the outing step since it's not approved
	if voteNo > voteYes {
		err = job.Database.DeleteOutingStep(outingStep.ID)
		if err != nil {
			return errors.Annotate(err, "delete unapproved outing step")
		}
		return nil // not approved
	}

	directConflicts := lo.Filter(collidingSet, func(step data.OutingStep, _ int) bool {
		return step.ID != outingStep.ID && StepCollidesWith(outingStep, step)
	})

	approvedColliding := lo.SomeBy(directConflicts, func(step data.OutingStep) bool {
		return step.Approved
	})

	if approvedColliding {
		return errors.New("exists approved colliding challenge - preconditions violated")
	}

	err = job.Database.ApproveOutingStep(outingStep.ID)
	if err != nil {
		return errors.Annotate(err, "approve outing step")
	}

	err = job.Database.DeleteOutingSteps(directConflicts)
	if err != nil {
		return errors.Annotate(err, "delete conflicting outing steps")
	}

	return nil
}
