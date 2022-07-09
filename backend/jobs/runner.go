package jobs

import (
	"encoding/json"
	"github.com/btubbs/pgq"
	"github.com/juju/errors"
	"gorm.io/gorm"
	"planlah.sg/backend/utils"
	"time"
)

type Runner struct {
	worker *pgq.Worker
}

const initJobsSql = `
BEGIN;
CREATE TABLE IF NOT EXISTS pgq_jobs (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  queue_name TEXT NOT NULL,
  data BYTEA NOT NULL,
  run_after TIMESTAMP WITH TIME ZONE NOT NULL,
  retry_waits TEXT[] NOT NULL,
  ran_at TIMESTAMP WITH TIME ZONE,
  error TEXT
);

-- Add an index for fast fetching of jobs by queue_name, sorted by run_after.  But only
-- index jobs that haven't been done yet, in case the user is keeping the job history around.
CREATE INDEX IF NOT EXISTS idx_pgq_jobs_fetch
	ON pgq_jobs (queue_name, run_after)
	WHERE ran_at IS NULL;
COMMIT;
`

var jobsRunner utils.Lazy[Runner]

// NewJobsRunner Creates a Jobs runner
func NewJobsRunner(conn *gorm.DB,
	voteDeadlineJob *VoteDeadlineJob,
) (*Runner, error) {
	return jobsRunner.LazyFallibleValue(func() (*Runner, error) {
		sqlDb, err := conn.DB()
		if err != nil {
			return nil, errors.Annotate(err, "jobsRunner get sqldb")
		}

		_, err = sqlDb.Exec(initJobsSql)
		if err != nil {
			return nil, errors.Annotate(err, "jobsRunner init sql")
		}

		// the default log is logrus, maybe try overriding it with a zap adapter
		worker := pgq.NewWorker(sqlDb)

		// register worker functions
		err = worker.RegisterQueue(VoteDeadlineJobName, voteDeadlineJob.Run)
		if err != nil {
			return nil, errors.Annotatef(err, "register job %s", VoteDeadlineJobName)
		}

		return &Runner{worker: worker}, nil
	})
}

func (runner *Runner) QueueVoteDeadlineJob(at time.Time, args VoteDeadlineJobArgs) error {
	bytes, err := json.Marshal(args)
	if err != nil {
		return errors.Annotate(err, "serialize VoteDeadlineJobArgs")
	}
	_, err = runner.worker.EnqueueJob(VoteDeadlineJobName, bytes, pgq.After(at)) // ignore jobID
	return errors.Annotate(err, "enqueue VoteDeadlineJob")
}

func (runner *Runner) Run() error {
	return errors.Annotate(runner.worker.Run(), "run jobsRunner")
}
