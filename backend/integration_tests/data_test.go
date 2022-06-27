package integrationtests

import (
	"os"
	"syscall"
	"testing"

	"github.com/joho/godotenv"
	"planlah.sg/backend/data"
	"planlah.sg/backend/utils"

	"github.com/stretchr/testify/suite"
)

type dataE2ETestSuite struct {
	suite.Suite
	db data.Database
}

func TestDataE2ETestSuite(t *testing.T) {
	suite.Run(t, &dataE2ETestSuite{})
}

func (s *dataE2ETestSuite) SetupSuite() {
	s.Require().NoError(godotenv.Load("../.test.env"))

	config, err := utils.NewConfig()
	s.Require().NoError(err)

	conn, err := data.NewPostgresGormDatabaseConnection(config)
	s.Require().NoError(err)

	db := data.NewDatabase(conn)
	s.db = db
}

func (s *dataE2ETestSuite) TearDownSuite() {
	p, _ := os.FindProcess(syscall.Getpid())
	p.Signal(syscall.SIGINT)
}

func (s *dataE2ETestSuite) SetupTest() {
	// reinit database
}

func (s *dataE2ETestSuite) TearDownTest() {
	// destroy database
}

func (s *dataE2ETestSuite) TestInit() {
	s.NotNil(s.db)
	// there should be 7 Users
	s.NotNil(s.db.GetUser(1))
	s.NotNil(s.db.GetUser(2))
	s.NotNil(s.db.GetUser(3))
	s.NotNil(s.db.GetUser(4))
	s.NotNil(s.db.GetUser(5))
	s.NotNil(s.db.GetUser(6))
	s.NotNil(s.db.GetUser(7))
	s.Nil(s.db.GetUser(8))

	// and only 5 groups
	s.NotNil(s.db.GetGroup(1))
	s.NotNil(s.db.GetGroup(2))
	s.NotNil(s.db.GetGroup(3))
	s.NotNil(s.db.GetGroup(4))
	s.NotNil(s.db.GetGroup(5))
	s.Nil(s.db.GetGroup(6))
}
