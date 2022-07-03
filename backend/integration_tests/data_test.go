package integrationtests

import (
	"github.com/lib/pq"
	"testing"
	"time"

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
	sqlDB, err := s.conn.DB()
	s.Require().NoError(err)
	err = sqlDB.Close()
	s.Require().NoError(err)

	// p, _ := os.FindProcess(syscall.Getpid())
	// _ = p.Signal(syscall.SIGINT) // ignored on Windows
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

	sqlDB, err := s.conn.DB()
	s.Require().NoError(err)
	err = sqlDB.Close()
	s.Require().NoError(err)
}

func (s *DataIntegrationTestSuite) Test_InitMigrate() {
	s.NotNil(s.db)
	// there should be 7 Users
	for i := 1; i <= 7; i++ {
		user, err := s.db.GetUser(uint(i))
		s.Equal(uint(i), user.ID)
		s.NoError(err)
	}
	_, err := s.db.GetUser(uint(8))
	s.ErrorIs(err, data.EntityNotFound)

	// and only 5 groups
	for i := 1; i <= 5; i++ {
		grp, err := s.db.GetGroup(0, uint(i))
		s.Equal(uint(i), grp.ID)
		s.NoError(err)
	}
	_, err = s.db.GetGroup(0, uint(6))
	s.ErrorIs(err, data.EntityNotFound)
}

func (s *DataIntegrationTestSuite) Test_CreateUser() {
	user := data.User{
		Username:    "user1",
		Name:        "User1",
		Gender:      "Male",
		Town:        "Town1",
		FirebaseUid: "firebaseUidValue1",
		ImageLink:   "link1",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err := s.db.CreateUser(&user)
	s.NoError(err)
	s.NotEmpty(user.ID)

	var userActual data.User
	err = s.conn.Where(&data.User{ID: user.ID}).Find(&userActual).Error
	s.NoError(err)
	s.Equal(user, userActual)
}

func (s *DataIntegrationTestSuite) Test_CreateUser_ThrowsUsernameNotFound_WhenUsernameConflict() {
	existingUser := data.User{
		Username:    "user1",
		Name:        "User1",
		Gender:      "Male",
		Town:        "Town1",
		FirebaseUid: "firebaseUidValue1",
		ImageLink:   "link1",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err := s.db.CreateUser(&existingUser)
	s.Require().NoError(err)
	s.NotEmpty(existingUser.ID)

	newUser := data.User{
		Username:    "user1", // same username
		Name:        "User2",
		Gender:      "Female",
		Town:        "Town2",
		FirebaseUid: "firebaseUidValue2",
		ImageLink:   "link2",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err = s.db.CreateUser(&newUser)
	s.ErrorIs(err, data.UsernameExists)
	s.Empty(newUser.ID)
}

func (s *DataIntegrationTestSuite) Test_CreateUser_ThrowsFirebaseUidExists_WhenFirebaseUidConflict() {
	existingUser := data.User{
		Username:    "user1",
		Name:        "User1",
		Gender:      "Male",
		Town:        "Town1",
		FirebaseUid: "firebaseUidValue1",
		ImageLink:   "link1",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err := s.db.CreateUser(&existingUser)
	s.Require().NoError(err)
	s.NotEmpty(existingUser.ID)

	newUser := data.User{
		Username:    "user2",
		Name:        "User2",
		Gender:      "Female",
		Town:        "Town2",
		FirebaseUid: "firebaseUidValue1", // same firebase uid
		ImageLink:   "link2",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err = s.db.CreateUser(&newUser)
	s.ErrorIs(err, data.FirebaseUidExists)
	s.Empty(newUser.ID)
}

// Finds which error is thrown when creating a User with existing username AND exiting firebase uid
func (s *DataIntegrationTestSuite) Test_CreateUser_ThrowsUsernameTakenFirst_WhenUsernameAndFirebaseUidConflict() {
	existingUser := data.User{
		Username:    "user1",
		Name:        "User1",
		Gender:      "Male",
		Town:        "Town1",
		FirebaseUid: "firebaseUidValue1",
		ImageLink:   "link1",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err := s.db.CreateUser(&existingUser)
	s.Require().NoError(err)
	s.NotEmpty(existingUser.ID)

	newUser := data.User{
		Username:    "user1",
		Name:        "User2",
		Gender:      "Female",
		Town:        "Town2",
		FirebaseUid: "firebaseUidValue1",
		ImageLink:   "link2",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err = s.db.CreateUser(&newUser)
	// throws UsernameExists not found
	s.ErrorIs(err, data.UsernameExists)
	s.Empty(newUser.ID)
}

func (s *DataIntegrationTestSuite) Test_GetUserByFirebaseUid_OnlyPopulatesID() {
	// exists in initial migration
	firebaseUid := "firebaseUid1"
	user, err := s.db.GetUserByFirebaseUid(firebaseUid)
	s.NoError(err)

	s.Equal(uint(1), user.ID)
	user.ID = 0
	s.Empty(user) // only ID is set
}

func (s *DataIntegrationTestSuite) Test_GetUserByFirebaseUid_ThrowsEntityNotFound_WhenNoSuchUser() {
	// does not exist in initial migration
	firebaseUid := "firebaseUid8"
	user, err := s.db.GetUserByFirebaseUid(firebaseUid)
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(user)
}

func (s *DataIntegrationTestSuite) Test_GetUser_PopulatesUser() {
	// exists in initial migration
	id := uint(1)
	user, err := s.db.GetUser(id)
	s.NoError(err)

	s.Equal(id, user.ID)
	// tests if properties are populated
	s.NotEmpty(user.Name)
	s.NotEmpty(user.Username)
}

func (s *DataIntegrationTestSuite) Test_GetUser_ThrowsEntityNotFound_WhenNoSuchUser() {
	// does not exist in initial migration
	id := uint(8)
	user, err := s.db.GetUser(id)
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(user)
}

func (s *DataIntegrationTestSuite) Test_GetAllGroups() {
	// populated in initial migration
	groups, err := s.db.GetAllGroups(1)
	s.NoError(err)

	s.Len(groups, 3)
	// TODO add more checks

	groups, err = s.db.GetAllGroups(4)
	s.NoError(err)

	s.Len(groups, 2)
	// TODO add more checks
}

func (s *DataIntegrationTestSuite) Test_GetAllGroups_NewUserHasNoGroups() {
	user := data.User{
		Username:    "user1",
		Name:        "User1",
		Gender:      "Male",
		Town:        "Town1",
		FirebaseUid: "firebaseUidValue1",
		ImageLink:   "link1",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err := s.db.CreateUser(&user)
	s.Require().NoError(err)

	groups, err := s.db.GetAllGroups(user.ID)
	s.NoError(err)

	s.Len(groups, 0)
	// TODO add more checks
}

func (s *DataIntegrationTestSuite) Test_GetGroup() {
	// populated in initial migration
	groups, err := s.db.GetGroup(4, 3)
	s.NoError(err)
	s.NotEmpty(groups)
	// TODO add more checks
}

func (s *DataIntegrationTestSuite) Test_GetGroup_Succeeds_WhenUserIsNotGroupMember() {
	// populated in initial migration
	groups, err := s.db.GetGroup(4, 1)
	s.NoError(err)
	s.NotEmpty(groups)
	// TODO add more checks
}

func (s *DataIntegrationTestSuite) Test_GetGroup_ThrowsEntityNotFound_WhenNoSuchGroup() {
	// not populated in initial migration
	groups, err := s.db.GetGroup(4, 6)
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(groups)
}

func (s *DataIntegrationTestSuite) Test_AddUserToGroup() {
	grpMember, err := s.db.AddUserToGroup(1, 4)
	s.NoError(err)
	s.Equal(uint(1), grpMember.UserID)
	s.Equal(uint(4), grpMember.GroupID)
	// For now, LastSeenMessageID is not init
	s.Empty(grpMember.LastSeenMessageID)
}

func (s *DataIntegrationTestSuite) Test_AddUserToGroup_ThrowsUserAlreadyInGroup_WhenUserAlreadyInGroup() {
	grpMember, err := s.db.AddUserToGroup(1, 1)
	s.ErrorIs(err, data.UserAlreadyInGroup)
	s.Empty(grpMember)
}

func (s *DataIntegrationTestSuite) Test_GetGroupMember() {
	grpMember, err := s.db.GetGroupMember(1, 1)
	s.NoError(err)
	s.Equal(uint(1), grpMember.UserID)
	s.Equal(uint(1), grpMember.GroupID)
}

func (s *DataIntegrationTestSuite) Test_GetGroupMember_Nil_WhenNotAGroupMember() {
	grpMember, err := s.db.GetGroupMember(1, 4)
	s.NoError(err)
	s.Nil(grpMember)
}

func (s *DataIntegrationTestSuite) Test_CreateGroup() {
	group := data.Group{
		Name:        "name1",
		Description: "description1",
		ImageLink:   "link1",
	}
	err := s.db.CreateGroup(&group)
	s.NoError(err)
	s.NotEmpty(group.ID)

	var groupActual data.Group
	err = s.conn.Where(&data.Group{ID: group.ID}).Find(&groupActual).Error
	s.NoError(err)

	s.Equal(group, groupActual)
}

func (s *DataIntegrationTestSuite) Test_UpdateGroupOwner() {
	err := s.db.UpdateGroupOwner(1, 1)
	s.NoError(err)
}

func (s *DataIntegrationTestSuite) Test_CreateMessage() {
	msg := data.Message{
		Content: "message1",
		SentAt:  time.Now(),
		ByID:    1,
	}
	err := s.db.CreateMessage(&msg)
	s.NoError(err)
	s.NotEmpty(msg.ID)
}

func (s *DataIntegrationTestSuite) Test_SetLastSeenMessageIDIfNewer_Succeeds_WhenLastSeenMessageIsNil() {
	grpId := uint(5)
	member, err := s.db.AddUserToGroup(1, grpId)
	s.Require().NoError(err)
	s.Require().Empty(member.LastSeenMessageID)

	sender, err := s.db.AddUserToGroup(2, grpId)
	s.Require().NoError(err)

	msg := data.Message{
		Content: "message1",
		SentAt:  time.Unix(5, 0),
		ByID:    sender.ID,
	}
	err = s.db.CreateMessage(&msg)
	s.Require().NoError(err)
	s.Require().NotEmpty(msg.ID)

	err = s.db.SetLastSeenMessageIDIfNewer(member.UserID, msg.ID)
	s.NoError(err)

	memberRefresh, err := s.db.GetGroupMember(member.UserID, grpId)
	s.Require().NoError(err)
	s.Require().NotNil(memberRefresh)

	s.Equal(memberRefresh.LastSeenMessageID, msg.ID)
}

func (s *DataIntegrationTestSuite) Test_SetLastSeenMessageIDIfNewer_Succeeds_WhenLastSeenMessageIsOlder() {
	grpId := uint(5)
	member, err := s.db.AddUserToGroup(1, grpId)
	s.Require().NoError(err)
	s.Require().Empty(member.LastSeenMessageID)

	sender, err := s.db.AddUserToGroup(2, grpId)
	s.Require().NoError(err)

	msg := data.Message{
		Content: "message1",
		SentAt:  time.Unix(5, 0),
		ByID:    sender.ID,
	}
	err = s.db.CreateMessage(&msg)
	s.Require().NoError(err)
	s.Require().NotEmpty(msg.ID)

	err = s.db.SetLastSeenMessageIDIfNewer(member.UserID, msg.ID)
	s.Require().NoError(err)

	memberRefresh, err := s.db.GetGroupMember(member.UserID, grpId)
	s.Require().NoError(err)
	s.Require().NotNil(memberRefresh)

	s.Require().Equal(memberRefresh.LastSeenMessageID, msg.ID)

	msgNewer := data.Message{
		Content: "message1",
		SentAt:  time.Unix(10, 0),
		ByID:    sender.ID,
	}
	err = s.db.CreateMessage(&msgNewer)
	s.Require().NoError(err)
	s.Require().NotEmpty(msgNewer.ID)

	err = s.db.SetLastSeenMessageIDIfNewer(member.UserID, msgNewer.ID)
	s.Require().NoError(err)

	memberRefresh2, err := s.db.GetGroupMember(member.UserID, grpId)
	s.Require().NoError(err)
	s.Require().NotNil(memberRefresh2)

	s.Equal(memberRefresh2.LastSeenMessageID, msgNewer.ID)
}

func (s *DataIntegrationTestSuite) Test_SetLastSeenMessageIDIfNewer_DoesNothing_WhenLastSeenMessageIsNotOlder() {
	grpId := uint(5)
	member, err := s.db.AddUserToGroup(1, grpId)
	s.Require().NoError(err)
	s.Require().Empty(member.LastSeenMessageID)

	sender, err := s.db.AddUserToGroup(2, grpId)
	s.Require().NoError(err)

	msg := data.Message{
		Content: "message1",
		SentAt:  time.Unix(5, 0),
		ByID:    sender.ID,
	}
	err = s.db.CreateMessage(&msg)
	s.Require().NoError(err)
	s.Require().NotEmpty(msg.ID)

	err = s.db.SetLastSeenMessageIDIfNewer(member.UserID, msg.ID)
	s.Require().NoError(err)

	memberRefresh, err := s.db.GetGroupMember(member.UserID, grpId)
	s.Require().NoError(err)
	s.Require().NotNil(memberRefresh)

	s.Require().Equal(memberRefresh.LastSeenMessageID, msg.ID)

	msgNewer := data.Message{
		Content: "message1",
		SentAt:  time.Unix(2, 0),
		ByID:    sender.ID,
	}
	err = s.db.CreateMessage(&msgNewer)
	s.Require().NoError(err)
	s.Require().NotEmpty(msgNewer.ID)

	err = s.db.SetLastSeenMessageIDIfNewer(member.UserID, msgNewer.ID)
	s.Require().NoError(err)

	memberRefresh2, err := s.db.GetGroupMember(member.UserID, grpId)
	s.Require().NoError(err)
	s.Require().NotNil(memberRefresh2)

	s.Equal(memberRefresh2.LastSeenMessageID, msg.ID)
}

func (s *DataIntegrationTestSuite) Test_SetLastSeenMessageIDIfNewer_DoesNothing_WhenNoSuchMessage() {
	grpId := uint(5)
	member, err := s.db.AddUserToGroup(1, grpId)
	s.Require().NoError(err)
	s.Require().Empty(member.LastSeenMessageID)

	err = s.db.SetLastSeenMessageIDIfNewer(member.UserID, uint(100))
	s.NoError(err)

	memberRefresh, err := s.db.GetGroupMember(member.UserID, grpId)
	s.Require().NoError(err)
	s.Require().NotNil(memberRefresh)

	s.Empty(memberRefresh.LastSeenMessageID)
}

func (s *DataIntegrationTestSuite) Test_SetLastSeenMessageIDIfNewer_DoesNothing_WhenMessageNotInUserGroups() {
	userId := uint(3)
	msgId := uint(7)

	// this message is in group 2, and user is not in that group
	err := s.db.SetLastSeenMessageIDIfNewer(userId, msgId)
	s.NoError(err)

	var cnt int64
	err = s.conn.Model(&data.GroupMember{}).
		Where(&data.GroupMember{UserID: userId, LastSeenMessageID: msgId}).
		Count(&cnt).Error
	s.Require().NoError(err)
	s.Equal(int64(0), cnt)
}

// TODO continue from GetMessagesRelative
