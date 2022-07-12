package jobs

import (
	"context"
	"encoding/json"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/juju/errors"
	"github.com/vgarvardt/gue/v3"
	"github.com/vgarvardt/gue/v3/adapter/pgxv4"
	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"
	"planlah.sg/backend/data"
	"planlah.sg/backend/utils"
	"time"
)

type Runner struct {
	client     *gue.Client
	workerPool *gue.WorkerPool
	logger     *zap.Logger
}

const initJobsSql = `
CREATE TABLE IF NOT EXISTS gue_jobs
(
    job_id      BIGSERIAL   NOT NULL PRIMARY KEY,
    priority    SMALLINT    NOT NULL,
    run_at      TIMESTAMPTZ NOT NULL,
    job_type    TEXT        NOT NULL,
    args        JSON        NOT NULL,
    error_count INTEGER     NOT NULL DEFAULT 0,
    last_error  TEXT,
    queue       TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_gue_jobs_selector ON gue_jobs (queue, run_at, priority);

COMMENT ON TABLE gue_jobs IS '1';
`

var jobsRunner utils.Lazy[Runner]

// NewJobsRunner Creates a Jobs runner
func NewJobsRunner(config *utils.Config, logger *zap.Logger,
	voteDeadlineJob *VoteDeadlineJob,
) (*Runner, error) {
	return jobsRunner.LazyFallibleValue(func() (*Runner, error) {
		dsn := data.DatabaseConnectionString(config)

		pgxCfg, err := pgxpool.ParseConfig(dsn)
		if err != nil {
			return nil, errors.Annotate(err, "parse pgx config")
		}

		pgxPool, err := pgxpool.ConnectConfig(context.Background(), pgxCfg)
		if err != nil {
			return nil, errors.Annotate(err, "create pgx connect config")
		}

		poolAdapter := pgxv4.NewConnPool(pgxPool)

		_, err = poolAdapter.Exec(context.Background(), initJobsSql)
		if err != nil {
			return nil, errors.Annotate(err, "migrate initial jobs")
		}

		gc := gue.NewClient(poolAdapter)
		if gc == nil {
			return nil, errors.Annotate(err, "create pgx client")
		}

		finishedJobsLog := func(ctx context.Context, j *gue.Job, err error) {
			if err != nil {
				logger.Error("job error", zap.String("job", j.Type), zap.Error(err))
			} else {
				logger.Info("job success", zap.String("job", j.Type))
			}
		}

		wm := gue.WorkMap{
			VoteDeadlineJobName: voteDeadlineJob.Run,
		}

		// create a pool w/ 2 workers
		workerPool := gue.NewWorkerPool(gc, wm, 4, gue.WithPoolHooksJobDone(finishedJobsLog))
		if workerPool == nil {
			return nil, errors.Annotate(err, "init worker pool")
		}

		return &Runner{client: gc, workerPool: workerPool, logger: logger}, nil
	})
}

func (runner *Runner) QueueVoteDeadlineJob(at time.Time, args VoteDeadlineJobArgs) error {
	bytes, err := json.Marshal(args)
	if err != nil {
		return errors.Annotate(err, "serialize VoteDeadlineJobArgs")
	}
	j := gue.Job{
		RunAt: at,
		Type:  VoteDeadlineJobName,
		Args:  bytes,
	}
	err = runner.client.Enqueue(context.Background(), &j)
	if err != nil {
		return errors.Annotate(err, "enqueue VoteDeadlineJob")
	}
	return nil
}

func (runner *Runner) Run() {
	// work jobs in goroutine
	g, gctx := errgroup.WithContext(context.Background())
	g.Go(func() error {
		err := runner.workerPool.Run(gctx)
		if err != nil {
			runner.logger.Fatal("workerPool err", zap.Error(err))
			return err
		}
		return err
	})
}
