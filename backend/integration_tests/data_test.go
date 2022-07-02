package integrationtests

import (
	"os"
	"syscall"
	"testing"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"github.com/joho/godotenv"
	"planlah.sg/backend/data"
	"planlah.sg/backend/utils"

	"github.com/stretchr/testify/suite"
)

type DataIntegrationTestSuite struct {
	suite.Suite
	db     *data.Database
	conn   *gorm.DB
	config *utils.Config
}

func TestDataE2ETestSuite(t *testing.T) {
	suite.Run(t, &DataIntegrationTestSuite{})
}

func (s *DataIntegrationTestSuite) SetupSuite() {
	s.Require().NoError(godotenv.Load("../.test.env"))

	config, err := utils.NewConfig()
	s.Require().NoError(err)
	s.config = config
}

func (s *DataIntegrationTestSuite) TearDownSuite() {
	p, _ := os.FindProcess(syscall.Getpid())
	_ = p.Signal(syscall.SIGINT) // ignored on Windows
}

func (s *DataIntegrationTestSuite) SetupTest() {
	// reinit database
	conn, err := data.NewDatabaseConnection(s.config, zap.NewNop())
	s.Require().NoError(err)

	db := data.NewDatabase(conn)

	s.db = db
	s.conn = conn
}

func (s *DataIntegrationTestSuite) TearDownTest() {
	// destroy database
	s.Require().NoError(s.conn.Exec(`
		DROP SCHEMA public CASCADE;
		CREATE SCHEMA public;
		GRANT ALL ON SCHEMA public TO postgres;
		GRANT ALL ON SCHEMA public TO public;
	`).Error)
}

func (s *DataIntegrationTestSuite) Test_InitMigrate() {
	s.NotNil(s.db)
	// there should be 7 Users
	for i := 1; i <= 7; i++ {
		user, err := s.db.GetUser(uint(i))
		s.Equal(uint(i), user.ID)
		s.Nil(err)
	}
	_, err := s.db.GetUser(uint(8))
	s.ErrorIs(err, data.EntityNotFound)

	// and only 5 groups
	for i := 1; i <= 5; i++ {
		grp, err := s.db.GetGroup(0, uint(i))
		s.Equal(uint(i), grp.ID)
		s.Nil(err)
	}
	_, err = s.db.GetGroup(0, uint(6))
	s.ErrorIs(err, data.EntityNotFound)
}

func (s *DataIntegrationTestSuite) Test_AddGroup() {
	group := data.Group{
		Name:        "groupName",
		Description: "groupDescription",
		ImageLink:   "imageLink",
	}
	err := s.db.CreateGroup(&group)
	s.Require().NoError(err)

	s.NotEqual(0, group.ID)
}
