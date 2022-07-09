package integrationtests

import (
	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/samber/lo"
	"math"
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

func (s *DataIntegrationTestSuite) Test_InitMigrate_Succeeds() {
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
		grp, err := s.db.GetGroup(1, uint(i))
		s.Equal(uint(i), grp.ID)
		s.NoError(err)
	}
	_, err = s.db.GetGroup(1, uint(6))
	s.ErrorIs(err, data.EntityNotFound)
}

func (s *DataIntegrationTestSuite) Test_CreateUser_Succeeds() {
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

func (s *DataIntegrationTestSuite) Test_GetUserByFirebaseUid_Succeeds_AndOnlyPopulatesID() {
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

func (s *DataIntegrationTestSuite) Test_GetUser_Succeeds_AndPopulatesUser() {
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

func (s *DataIntegrationTestSuite) Test_GetAllGroups_Succeeds() {
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

func (s *DataIntegrationTestSuite) Test_GetAllGroups_Succeeds_NewUserHasNoGroups() {
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

func (s *DataIntegrationTestSuite) Test_GetAllGroups_DMAndNormalGroups() {
	user1 := data.User{
		Username:    "user1",
		Name:        "User1",
		Gender:      "Male",
		Town:        "Town1",
		FirebaseUid: "firebaseUidValue1",
		ImageLink:   "link1",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err := s.db.CreateUser(&user1)
	s.Require().NoError(err)

	user2 := data.User{
		Username:    "user2",
		Name:        "User2",
		Gender:      "Male",
		Town:        "Town2",
		FirebaseUid: "firebaseUidValue2",
		ImageLink:   "link2",
		Attractions: pq.Float64Array{},
		Food:        pq.Float64Array{},
	}
	err = s.db.CreateUser(&user2)
	s.Require().NoError(err)

	normalGroup := data.Group{
		Name:        "gname1",
		Description: "gdesc1",
		ImageLink:   "glink1",
		IsDM:        false,
	}
	err = s.db.CreateGroup(&normalGroup)
	s.Require().NoError(err)

	_, err = s.db.AddUserToGroup(user1.ID, normalGroup.ID)
	s.Require().NoError(err)

	groups, err := s.db.GetAllGroups(user1.ID)
	s.NoError(err)
	s.Len(groups, 1)

	_, err = s.db.SendFriendRequest(user1.ID, user2.ID)
	s.Require().NoError(err)
	st, err := s.db.SendFriendRequest(user2.ID, user1.ID)
	s.Require().NoError(err)
	s.Require().Equal(data.Approved, st)

	dmGroup, err := s.db.CreateDMGroup(user1.ID, user2.ID)
	s.Require().NoError(err)

	groups, err = s.db.GetAllGroups(user1.ID)
	s.NoError(err)
	s.Len(groups, 2)

	s.Equal(groups[1].ID, dmGroup.ID)
	s.Equal(groups[1].Name, "User2")
	s.Equal(groups[1].ImageLink, "link2")

	groups, err = s.db.GetAllGroups(user2.ID)
	s.NoError(err)
	s.Len(groups, 1)

	s.Equal(groups[0].ID, dmGroup.ID)
	s.Equal(groups[0].Name, "User1")
	s.Equal(groups[0].ImageLink, "link1")
}

func (s *DataIntegrationTestSuite) Test_GetGroup_Succeeds() {
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

func (s *DataIntegrationTestSuite) Test_AddUserToGroup_Succeeds() {
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

func (s *DataIntegrationTestSuite) Test_GetGroupMember_Succeeds() {
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

func (s *DataIntegrationTestSuite) Test_CreateGroup_Succeeds() {
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

func (s *DataIntegrationTestSuite) Test_UpdateGroupOwner_Succeeds() {
	err := s.db.UpdateGroupOwner(1, 1)
	s.NoError(err)
}

func (s *DataIntegrationTestSuite) Test_CreateMessage_Succeeds() {
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

func (s *DataIntegrationTestSuite) Test_GetMessagesRelative_Succeeds_AfterInCorrectOrder() {
	msgs, err := s.db.GetMessagesRelative(1, 11, 50, false)
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	s.Equal([]uint{11, 12, 13, 14, 15}, ids)
}

func (s *DataIntegrationTestSuite) Test_GetMessagesRelative_Succeeds_BeforeInCorrectOrder() {
	msgs, err := s.db.GetMessagesRelative(1, 11, 50, true)
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	// the order must be the same as well
	s.Equal([]uint{9, 10, 11}, ids)
	s.NotEqual([]uint{11, 10, 9}, ids)
}

func (s *DataIntegrationTestSuite) Test_GetMessagesRelative_Succeeds_AfterInCorrectOrderAndLimitCount() {
	msgs, err := s.db.GetMessagesRelative(1, 11, 2, false)
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	s.Equal([]uint{11, 12}, ids)
}

func (s *DataIntegrationTestSuite) Test_GetMessagesRelative_Succeeds_BeforeInCorrectOrderAndLimitCount() {
	msgs, err := s.db.GetMessagesRelative(1, 11, 2, true)
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	// the order must be the same as well
	s.Equal([]uint{10, 11}, ids)
	s.NotEqual([]uint{10, 9}, ids)
	s.NotEqual([]uint{11, 10}, ids)
}

func (s *DataIntegrationTestSuite) Test_GetMessagesRelative_ThrowsEntityNotFound_WhenMessageIsNotInUserGroups() {
	msgs, err := s.db.GetMessagesRelative(3, 5, 50, true)
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(msgs)
	msgs, err = s.db.GetMessagesRelative(3, 5, 50, false)
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(msgs)
}

func (s *DataIntegrationTestSuite) Test_GetMessagesRelative_ThrowsEntityNotFound_WhenNoSuchMessage() {
	msgs, err := s.db.GetMessagesRelative(3, 100, 50, true)
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(msgs)
	msgs, err = s.db.GetMessagesRelative(3, 100, 50, false)
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(msgs)
}

func (s *DataIntegrationTestSuite) Test_GetMessages_Succeeds() {
	initial, err := time.ParseInLocation("2006-01-02 15:04", "2016-01-01 00:00", time.FixedZone("UTC+10", 10*60*60))
	s.Require().NoError(err)
	msgs, err := s.db.GetMessages(3, initial.Add(8*time.Minute), initial.Add(14*time.Minute))
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	s.Equal(ids, []uint{9, 10, 11, 12, 13, 14}) // exclude last one due to exclusive >
}

func (s *DataIntegrationTestSuite) Test_GetMessages_Succeeds_Limited() {
	initial, err := time.ParseInLocation("2006-01-02 15:04", "2016-01-01 00:00", time.FixedZone("UTC+10", 10*60*60))
	s.Require().NoError(err)
	msgs, err := s.db.GetMessages(3, initial.Add(11*time.Minute), initial.Add(13*time.Minute))
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	s.Equal(ids, []uint{12, 13}) // exclude last one due to exclusive >
}

func (s *DataIntegrationTestSuite) Test_GetMessages_Empty_WhenNoSuchGroup() {
	msgs, err := s.db.GetMessages(100, time.UnixMilli(0), time.UnixMilli(math.MaxInt64))
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	s.Equal(ids, []uint{})
}

func (s *DataIntegrationTestSuite) Test_GetMessages_Empty_WhenTimeRangeInvalid() {
	msgs, err := s.db.GetMessages(3, time.UnixMilli(math.MaxInt64), time.UnixMilli(0))
	s.NoError(err)
	ids := lo.Map(msgs, func(t data.Message, _ int) uint {
		return t.ID
	})
	s.Equal(ids, []uint{})
}

func (s *DataIntegrationTestSuite) Test_CreateOuting_Succeeds() {
	outing := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "description1",
		Start:       time.Now(),
		End:         time.Now().Add(time.Hour),
	}
	err := s.db.CreateOuting(&outing)
	s.NoError(err)
	s.NotEmpty(outing.ID)
}

func (s *DataIntegrationTestSuite) Test_CreateOutingStep_Succeeds() {
	place := data.Place{
		ID:       0,
		Name:     "placeName1",
		Location: "placeLocation1",
		Position: data.Point{
			Longitude: 140,
			Latitude:  50,
		},
		FormattedAddress: "placeFmtAddress1",
		ImageUrl:         "placeImageUrl1",
		About:            "placeAbout1",
		PlaceType:        data.Attraction,
	}
	err := s.conn.Create(&place).Error
	s.Require().NoError(err)
	s.Require().NotEmpty(place.ID)

	outing := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "description1",
		Start:       time.Now(),
		End:         time.Now().Add(time.Hour),
	}
	err = s.db.CreateOuting(&outing)
	s.Require().NoError(err)
	s.Require().NotEmpty(outing.ID)

	outingStep := data.OutingStep{
		OutingID:     outing.ID,
		PlaceID:      place.ID,
		Approved:     true,
		Description:  "description1",
		Start:        time.Now(),
		End:          time.Now().Add(time.Hour),
		VoteDeadline: time.Now().Add(time.Hour * 5),
	}
	err = s.db.CreateOutingStep(&outingStep)
	s.NoError(err)
	s.NotEmpty(outingStep.ID)
}

func (s *DataIntegrationTestSuite) Test_CreateOutingStep_ThrowsEntityNotFound_WhenPlaceIsNotFound() {
	outing := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "description1",
		Start:       time.Now(),
		End:         time.Now().Add(time.Hour),
	}
	err := s.db.CreateOuting(&outing)
	s.Require().NoError(err)
	s.Require().NotEmpty(outing.ID)

	outingStep := data.OutingStep{
		OutingID:     outing.ID,
		PlaceID:      100, // not found
		Approved:     true,
		Description:  "description1",
		Start:        time.Now(),
		End:          time.Now().Add(time.Hour),
		VoteDeadline: time.Now().Add(time.Hour * 5),
	}
	err = s.db.CreateOutingStep(&outingStep)
	s.ErrorIs(err, data.EntityNotFound)
}

func (s *DataIntegrationTestSuite) createSampleOutingStep() data.OutingStep {

	place := data.Place{
		ID:       0,
		Name:     "placeName1",
		Location: "placeLocation1",
		Position: data.Point{
			Longitude: 140,
			Latitude:  50,
		},
		FormattedAddress: "placeFmtAddress1",
		ImageUrl:         "placeImageUrl1",
		About:            "placeAbout1",
		PlaceType:        data.Attraction,
	}
	err := s.conn.Create(&place).Error
	s.Require().NoError(err)
	s.Require().NotEmpty(place.ID)

	outing := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "description1",
		Start:       time.Now(),
		End:         time.Now().Add(time.Hour),
	}
	err = s.db.CreateOuting(&outing)
	s.Require().NoError(err)
	s.Require().NotEmpty(outing.ID)

	outingStep := data.OutingStep{
		OutingID:     outing.ID,
		Description:  "description1",
		PlaceID:      place.ID,
		Approved:     true,
		Start:        time.Now(),
		End:          time.Now().Add(time.Hour),
		VoteDeadline: time.Now().Add(time.Hour * 5),
	}
	err = s.db.CreateOutingStep(&outingStep)
	s.Require().NoError(err)
	s.Require().NotEmpty(outingStep.ID)

	return outingStep
}

func (s *DataIntegrationTestSuite) upsertOutingStepVote_getSolidaryVote() data.OutingStepVote {
	outings, err := s.db.GetAllOutings(3)
	s.Require().NoError(err)
	s.Require().Len(outings, 1)
	s.Require().Len(outings[0].Steps, 1)
	s.Require().Len(outings[0].Steps[0].Votes, 1)
	return outings[0].Steps[0].Votes[0]
}

func (s *DataIntegrationTestSuite) Test_UpsertOutingStepVote_Succeeds_WhenNoPreviousVoteAndVoteTrue() {
	outingStep := s.createSampleOutingStep()

	vote := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          true,
		VotedAt:       time.Now(),
	}
	err := s.db.UpsertOutingStepVote(&vote)
	s.NoError(err)

	dbVote := s.upsertOutingStepVote_getSolidaryVote()
	s.Equal(vote.OutingStepID, dbVote.OutingStepID)
	s.Equal(vote.GroupMemberID, dbVote.GroupMemberID)
	s.Equal(true, dbVote.Vote)
}

func (s *DataIntegrationTestSuite) Test_UpsertOutingStepVote_Succeeds_WhenNoPreviousVoteAndVoteFalse() {
	outingStep := s.createSampleOutingStep()

	vote := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          false,
		VotedAt:       time.Now(),
	}
	err := s.db.UpsertOutingStepVote(&vote)
	s.NoError(err)

	dbVote := s.upsertOutingStepVote_getSolidaryVote()
	s.Equal(vote.OutingStepID, dbVote.OutingStepID)
	s.Equal(vote.GroupMemberID, dbVote.GroupMemberID)
	s.Equal(false, dbVote.Vote)
}

func (s *DataIntegrationTestSuite) Test_UpsertOutingStepVote_Succeeds_WhenPreviousVoteTrueAndVoteTrue() {
	outingStep := s.createSampleOutingStep()

	vote := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          true,
		VotedAt:       time.Now(),
	}
	err := s.db.UpsertOutingStepVote(&vote)
	s.Require().NoError(err)
	dbVote := s.upsertOutingStepVote_getSolidaryVote()
	s.Require().Equal(vote.OutingStepID, dbVote.OutingStepID)
	s.Require().Equal(vote.GroupMemberID, dbVote.GroupMemberID)
	s.Require().Equal(true, dbVote.Vote)

	vote1 := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          true,
		VotedAt:       time.Now(),
	}
	err = s.db.UpsertOutingStepVote(&vote1)
	s.NoError(err)
	dbVote1 := s.upsertOutingStepVote_getSolidaryVote()
	s.Equal(vote1.OutingStepID, dbVote1.OutingStepID)
	s.Equal(vote1.GroupMemberID, dbVote1.GroupMemberID)
	s.Equal(true, dbVote1.Vote)
}

func (s *DataIntegrationTestSuite) Test_UpsertOutingStepVote_Succeeds_WhenPreviousVoteTrueAndVoteFalse() {
	outingStep := s.createSampleOutingStep()

	vote := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          true,
		VotedAt:       time.Now(),
	}
	err := s.db.UpsertOutingStepVote(&vote)
	s.Require().NoError(err)
	dbVote := s.upsertOutingStepVote_getSolidaryVote()
	s.Require().Equal(vote.OutingStepID, dbVote.OutingStepID)
	s.Require().Equal(vote.GroupMemberID, dbVote.GroupMemberID)
	s.Require().Equal(true, dbVote.Vote)

	vote1 := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          false,
		VotedAt:       time.Now(),
	}
	err = s.db.UpsertOutingStepVote(&vote1)
	s.NoError(err)
	dbVote1 := s.upsertOutingStepVote_getSolidaryVote()
	s.Equal(vote1.OutingStepID, dbVote1.OutingStepID)
	s.Equal(vote1.GroupMemberID, dbVote1.GroupMemberID)
	s.Equal(false, dbVote1.Vote)
}

func (s *DataIntegrationTestSuite) Test_UpsertOutingStepVote_Succeeds_WhenPreviousVoteFalseAndVoteTrue() {
	outingStep := s.createSampleOutingStep()

	vote := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          false,
		VotedAt:       time.Now(),
	}
	err := s.db.UpsertOutingStepVote(&vote)
	s.Require().NoError(err)
	dbVote := s.upsertOutingStepVote_getSolidaryVote()
	s.Require().Equal(vote.OutingStepID, dbVote.OutingStepID)
	s.Require().Equal(vote.GroupMemberID, dbVote.GroupMemberID)
	s.Require().Equal(false, dbVote.Vote)

	vote1 := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          true,
		VotedAt:       time.Now(),
	}
	err = s.db.UpsertOutingStepVote(&vote1)
	s.NoError(err)
	dbVote1 := s.upsertOutingStepVote_getSolidaryVote()
	s.Equal(vote1.OutingStepID, dbVote1.OutingStepID)
	s.Equal(vote1.GroupMemberID, dbVote1.GroupMemberID)
	s.Equal(true, dbVote1.Vote)
}

func (s *DataIntegrationTestSuite) Test_UpsertOutingStepVote_Succeeds_WhenPreviousVoteFalseAndVoteFalse() {
	outingStep := s.createSampleOutingStep()

	vote := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          false,
		VotedAt:       time.Now(),
	}
	err := s.db.UpsertOutingStepVote(&vote)
	s.Require().NoError(err)
	dbVote := s.upsertOutingStepVote_getSolidaryVote()
	s.Require().Equal(vote.OutingStepID, dbVote.OutingStepID)
	s.Require().Equal(vote.GroupMemberID, dbVote.GroupMemberID)
	s.Require().Equal(false, dbVote.Vote)

	vote1 := data.OutingStepVote{
		GroupMemberID: 9,
		OutingStepID:  outingStep.ID,
		Vote:          false,
		VotedAt:       time.Now(),
	}
	err = s.db.UpsertOutingStepVote(&vote1)
	s.NoError(err)
	dbVote1 := s.upsertOutingStepVote_getSolidaryVote()
	s.Equal(vote1.OutingStepID, dbVote1.OutingStepID)
	s.Equal(vote1.GroupMemberID, dbVote1.GroupMemberID)
	s.Equal(false, dbVote1.Vote)
}

// TODO no need to test OutingStepVote's EntityNotFound, just rewrite it

func (s *DataIntegrationTestSuite) Test_GetOuting_Succeeds() {
	outing := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "description1",
		Start:       time.Now(),
		End:         time.Now().Add(time.Hour),
	}
	err := s.db.CreateOuting(&outing)
	s.Require().NoError(err)
	s.Require().NotEmpty(outing.ID)

	dbOuting, err := s.db.GetOuting(outing.ID)
	s.NoError(err)
	s.Equal(outing.ID, dbOuting.ID)
}

func (s *DataIntegrationTestSuite) Test_GetOuting_ThrowsEntityNotFound_WhenNoSuchOuting() {
	dbOuting, err := s.db.GetOuting(uint(100))
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(dbOuting)
}

func (s *DataIntegrationTestSuite) Test_GetOutingAndGroupForOutingStep_Succeeds() {
	outingStep := s.createSampleOutingStep()
	v, err := s.db.GetOutingAndGroupForOutingStep(outingStep.ID)
	s.NoError(err)
	s.Equal(data.OutingAndGroupID{
		GroupID:  3,
		OutingID: 1,
	}, v)
}

func (s *DataIntegrationTestSuite) Test_GetOutingAndGroupForOutingStep_ThrowsEntityNotFound_WhenNoSuchOutingStep() {
	v, err := s.db.GetOutingAndGroupForOutingStep(uint(100))
	s.ErrorIs(err, data.EntityNotFound)
	s.Empty(v)
}

func (s *DataIntegrationTestSuite) Test_GetAllOutings_Succeeds_WhenNoOutings() {
	v, err := s.db.GetAllOutings(3)
	s.NoError(err)
	s.Len(v, 0)
}

func (s *DataIntegrationTestSuite) Test_GetAllOutings_Succeeds_WhenMoreOutings() {
	outing1 := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "desc1",
		Start:       time.Time{},
		End:         time.Time{},
	}
	err := s.db.CreateOuting(&outing1)
	s.Require().NoError(err)

	outing2 := data.Outing{
		GroupID:     3,
		Name:        "name2",
		Description: "desc2",
		Start:       time.Time{},
		End:         time.Time{},
	}
	err = s.db.CreateOuting(&outing2)
	s.Require().NoError(err)

	// in another group
	outing3 := data.Outing{
		GroupID:     2,
		Name:        "name3",
		Description: "desc3",
		Start:       time.Time{},
		End:         time.Time{},
	}
	err = s.db.CreateOuting(&outing3)
	s.Require().NoError(err)

	outings, err := s.db.GetAllOutings(3)
	s.NoError(err)
	s.Equal(lo.Map(outings, func(t data.Outing, _ int) uint {
		return t.ID
	}), []uint{outing1.ID, outing2.ID})

	outings, err = s.db.GetAllOutings(2)
	s.NoError(err)
	s.Equal(lo.Map(outings, func(t data.Outing, _ int) uint {
		return t.ID
	}), []uint{outing3.ID})
}

func (s *DataIntegrationTestSuite) Test_GetActiveOuting_Nil_WhenNoActiveOuting() {
	outing, err := s.db.GetActiveOuting(3)
	s.NoError(err)
	s.Nil(outing)
}

func (s *DataIntegrationTestSuite) Test_GetActiveOuting_Succeeds() {
	outing1 := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "desc1",
		Start:       time.Time{},
		End:         time.Time{},
	}
	err := s.db.CreateOuting(&outing1)
	s.Require().NoError(err)

	err = s.db.UpdateActiveOuting(3, outing1.ID)
	s.Require().NoError(err)

	dbOuting, err := s.db.GetActiveOuting(3)
	s.NoError(err)
	s.Equal(outing1.ID, dbOuting.ID)
}

func (s *DataIntegrationTestSuite) Test_UpdateActiveOuting_Succeeds_WhenNoActiveOuting() {
	outing1 := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "desc1",
		Start:       time.Time{},
		End:         time.Time{},
	}
	err := s.db.CreateOuting(&outing1)
	s.Require().NoError(err)

	dbOuting, err := s.db.GetActiveOuting(3)
	s.Require().NoError(err)
	s.Require().Nil(dbOuting)

	err = s.db.UpdateActiveOuting(3, outing1.ID)
	s.NoError(err)

	dbOuting, err = s.db.GetActiveOuting(3)
	s.Require().NoError(err)
	s.Require().Equal(outing1.ID, dbOuting.ID)
}

func (s *DataIntegrationTestSuite) Test_UpdateActiveOuting_Succeeds_WhenExistsActiveOuting() {
	outing1 := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "desc1",
		Start:       time.Time{},
		End:         time.Time{},
	}
	err := s.db.CreateOuting(&outing1)
	s.Require().NoError(err)

	dbOuting, err := s.db.GetActiveOuting(3)
	s.Require().NoError(err)
	s.Require().Nil(dbOuting)

	err = s.db.UpdateActiveOuting(3, outing1.ID)
	s.NoError(err)

	dbOuting, err = s.db.GetActiveOuting(3)
	s.Require().NoError(err)
	s.Require().Equal(outing1.ID, dbOuting.ID)

	outing2 := data.Outing{
		GroupID:     3,
		Name:        "name1",
		Description: "desc1",
		Start:       time.Time{},
		End:         time.Time{},
	}
	err = s.db.CreateOuting(&outing2)
	s.Require().NoError(err)

	err = s.db.UpdateActiveOuting(3, outing2.ID)
	s.NoError(err)

	dbOuting, err = s.db.GetActiveOuting(3)
	s.Require().NoError(err)
	s.Require().Equal(outing2.ID, dbOuting.ID)
}

func (s *DataIntegrationTestSuite) Test_CreateGroupInvite_Succeeds_NonNilExpiry() {
	timeNow := time.Now().Add(time.Hour)
	exp := &timeNow
	inv := data.GroupInvite{
		Expiry:  exp,
		Active:  true,
		GroupID: 3,
	}
	err := s.db.CreateGroupInvite(&inv)
	s.NoError(err)
	s.NotEmpty(inv.ID)
}

func (s *DataIntegrationTestSuite) Test_CreateGroupInvite_Succeeds_NilExpiry() {
	inv := data.GroupInvite{
		Expiry:  nil,
		Active:  true,
		GroupID: 3,
	}
	err := s.db.CreateGroupInvite(&inv)
	s.NoError(err)
	s.NotEmpty(inv.ID)
}

func (s *DataIntegrationTestSuite) Test_CreateGroupInvite_Succeeds_WithDifferentID() {
	timeNow := time.Now().Add(time.Hour)
	exp := &timeNow
	inv := data.GroupInvite{
		Expiry:  exp,
		Active:  true,
		GroupID: 3,
	}
	err := s.db.CreateGroupInvite(&inv)
	s.Require().NoError(err)
	s.Require().NotEmpty(inv.ID)

	inv2 := data.GroupInvite{
		GroupID: 3,
	}
	err = s.db.CreateGroupInvite(&inv2)
	s.NoError(err)
	s.NotEmpty(inv.ID)
	s.NotEqual(inv.ID, inv2.ID)
}

func (s *DataIntegrationTestSuite) initGroupInviteStates() []data.GroupInvite {
	timeNow := time.Now().Add(time.Hour)
	exp := &timeNow
	inv := data.GroupInvite{
		Expiry:  exp,
		Active:  true,
		GroupID: 3,
	}
	err := s.db.CreateGroupInvite(&inv)
	s.Require().NoError(err)
	s.Require().NotEmpty(inv.ID)

	inv2 := data.GroupInvite{
		Expiry:  nil,
		Active:  true,
		GroupID: 3,
	}
	err = s.db.CreateGroupInvite(&inv2)
	s.Require().NoError(err)
	s.Require().NotEmpty(inv2.ID)

	inv3 := data.GroupInvite{
		Expiry:  nil,
		Active:  true,
		GroupID: 2,
	}
	err = s.db.CreateGroupInvite(&inv3)
	s.Require().NoError(err)
	s.Require().NotEmpty(inv3.ID)
	return []data.GroupInvite{inv, inv2, inv3}
}

func (s *DataIntegrationTestSuite) Test_GetGroupInvites_Succeeds() {
	invsdb := s.initGroupInviteStates()

	invs, err := s.db.GetGroupInvites(3)
	s.NoError(err)
	s.Equal(lo.Map(invs, func(t data.GroupInvite, _ int) uuid.UUID {
		return t.ID
	}), []uuid.UUID{invsdb[0].ID, invsdb[1].ID})

	invs, err = s.db.GetGroupInvites(2)
	s.NoError(err)
	s.Equal(lo.Map(invs, func(t data.GroupInvite, _ int) uuid.UUID {
		return t.ID
	}), []uuid.UUID{invsdb[2].ID})
}

func (s *DataIntegrationTestSuite) Test_InvalidateInvite_Succeeds() {
	invsdb := s.initGroupInviteStates()

	invs, err := s.db.GetGroupInvites(3)
	s.Require().NoError(err)
	s.Require().Equal(lo.Map(invs, func(t data.GroupInvite, _ int) uuid.UUID {
		return t.ID
	}), []uuid.UUID{invsdb[0].ID, invsdb[1].ID})

	invs, err = s.db.GetGroupInvites(2)
	s.Require().NoError(err)
	s.Require().Equal(lo.Map(invs, func(t data.GroupInvite, _ int) uuid.UUID {
		return t.ID
	}), []uuid.UUID{invsdb[2].ID})

	err = s.db.InvalidateInvite(1, invsdb[0].ID)
	s.NoError(err)

	invs, err = s.db.GetGroupInvites(3)
	s.Require().NoError(err)
	s.Require().Equal(lo.Map(invs, func(t data.GroupInvite, _ int) uuid.UUID {
		return t.ID
	}), []uuid.UUID{invsdb[1].ID})
}

func (s *DataIntegrationTestSuite) Test_JoinByInvite_ThrowsUserAlreadyInGroup_WhenUserAlreadyInGroup() {
	invsdb := s.initGroupInviteStates()
	_, err := s.db.JoinByInvite(1, invsdb[0].ID)
	s.ErrorIs(err, data.UserAlreadyInGroup)
}

func (s *DataIntegrationTestSuite) Test_JoinByInvite_ThrowsEntityNotFound_WhenNoSuchInvite() {
	_, err := s.db.JoinByInvite(1, uuid.UUID{})
	s.ErrorIs(err, data.EntityNotFound)
}

func (s *DataIntegrationTestSuite) Test_JoinByInvite_Succeeds() {
	invsdb := s.initGroupInviteStates()
	inv, err := s.db.JoinByInvite(3, invsdb[2].ID) // join group 2
	s.NoError(err)
	s.NotEmpty(inv)
	s.Equal(inv.GroupID, uint(2))
}

func (s *DataIntegrationTestSuite) Test_SearchUsers_Succeeds() {
	users, err := s.db.SearchForFriends(1, "a", 0)
	s.NoError(err)
	s.Len(users, 5)

	users, err = s.db.SearchForFriends(1, "dad", 0)
	s.NoError(err)
	s.Len(users, 1)
}

// TODO more cases

func (s *DataIntegrationTestSuite) Test_SendFriendRequest_Success() {
	// TODO split these into their own functions
	stat, err := s.db.SendFriendRequest(1, 3)
	s.NoError(err)
	s.Equal(data.Pending, stat)

	stat, err = s.db.SendFriendRequest(1, 3)
	s.ErrorIs(err, data.FriendRequestExists)

	stat, err = s.db.SendFriendRequest(1, 100)
	s.ErrorIs(err, data.EntityNotFound)

	stat, err = s.db.SendFriendRequest(3, 1)
	s.NoError(err)
	s.Equal(data.Approved, stat)

	stat, err = s.db.SendFriendRequest(4, 4)
	s.ErrorIs(err, data.IsSameUser)
}

func (s *DataIntegrationTestSuite) Test_ApproveFriendRequest_Success() {
	stat, err := s.db.SendFriendRequest(1, 3)
	s.Require().NoError(err)
	s.Require().Equal(data.Pending, stat)

	err = s.db.ApproveFriendRequest(1, 3)
	s.NoError(err)

	var req data.FriendRequest
	err = s.conn.Model(&data.FriendRequest{
		FromID: 1,
		ToID:   3,
	}).Find(&req).Error
	s.Require().NoError(err)
	s.Equal(req.Status, data.Approved)
}

func (s *DataIntegrationTestSuite) Test_ApproveFriendRequest_Succeeds_WhenAlreadyRejected() {
	stat, err := s.db.SendFriendRequest(1, 3)
	s.Require().NoError(err)
	s.Require().Equal(data.Pending, stat)

	err = s.db.RejectFriendRequest(1, 3)
	s.Require().NoError(err)

	err = s.db.ApproveFriendRequest(1, 3)
	s.NoError(err)

	var req data.FriendRequest
	err = s.conn.Model(&data.FriendRequest{
		FromID: 1,
		ToID:   3,
	}).Find(&req).Error
	s.Require().NoError(err)
	s.Equal(req.Status, data.Approved)
}

func (s *DataIntegrationTestSuite) Test_RejectFriendRequest_Success() {
	stat, err := s.db.SendFriendRequest(1, 3)
	s.Require().NoError(err)
	s.Require().Equal(data.Pending, stat)

	err = s.db.RejectFriendRequest(1, 3)
	s.NoError(err)

	var req data.FriendRequest
	err = s.conn.Model(&data.FriendRequest{
		FromID: 1,
		ToID:   3,
	}).Find(&req).Error
	s.Require().NoError(err)
	s.Equal(req.Status, data.Rejected)
}

func (s *DataIntegrationTestSuite) Test_PendingFriendRequests_Success() {
	stat, err := s.db.SendFriendRequest(1, 3)
	s.Require().NoError(err)
	s.Require().Equal(data.Pending, stat)

	stat, err = s.db.SendFriendRequest(2, 3)
	s.Require().NoError(err)
	s.Require().Equal(data.Pending, stat)

	reqs, err := s.db.PendingFriendRequests(3, 0)
	s.NoError(err)
	s.Len(reqs, 2)

	err = s.db.RejectFriendRequest(1, 3)
	s.Require().NoError(err)

	reqs, err = s.db.PendingFriendRequests(3, 0)
	s.NoError(err)
	s.Len(reqs, 1)

	err = s.db.ApproveFriendRequest(2, 3)
	s.Require().NoError(err)

	reqs, err = s.db.PendingFriendRequests(3, 0)
	s.NoError(err)
	s.Len(reqs, 0)
}

func (s *DataIntegrationTestSuite) Test_ListFriends_Success() {
	stat, err := s.db.SendFriendRequest(1, 3)
	s.Require().NoError(err)
	s.Require().Equal(data.Pending, stat)

	stat, err = s.db.SendFriendRequest(2, 3)
	s.Require().NoError(err)
	s.Require().Equal(data.Pending, stat)

	err = s.db.ApproveFriendRequest(2, 3)
	s.Require().NoError(err)

	frens, err := s.db.ListFriends(3, 0)
	s.NoError(err)
	s.Len(frens, 1)

	err = s.db.ApproveFriendRequest(1, 3)
	s.Require().NoError(err)

	frens, err = s.db.ListFriends(3, 0)
	s.NoError(err)
	s.Len(frens, 2)
}

// TODO tests for IsFriends

func (s *DataIntegrationTestSuite) Test_SearchForPlaces_Succeeds() {
	place := data.Place{
		ID:       0,
		Name:     "placeName1",
		Location: "placeLocation1",
		Position: data.Point{
			Longitude: 140.5367,
			Latitude:  50.1234,
		},
		FormattedAddress: "placeFmtAddress1",
		ImageUrl:         "placeImageUrl1",
		About:            "placeAbout1",
		PlaceType:        data.Attraction,
	}
	err := s.conn.Create(&place).Error
	s.Require().NoError(err)
	s.Require().NotEmpty(place.ID)

	place1 := data.Place{
		ID:       0,
		Name:     "placeName2",
		Location: "placeLocation1",
		Position: data.Point{
			Longitude: 120.89333,
			Latitude:  50.1299,
		},
		FormattedAddress: "placeFmtAddress1",
		ImageUrl:         "placeImageUrl1",
		About:            "placeAbout1",
		PlaceType:        data.Attraction,
	}
	err = s.conn.Create(&place1).Error
	s.Require().NoError(err)
	s.Require().NotEmpty(place.ID)

	places, err := s.db.SearchForPlaces("place", 0)
	s.NoError(err)
	s.Len(places, 2)
	s.Equal(data.Point{
		Longitude: 140.5367,
		Latitude:  50.1234,
	}, places[0].Position)
	s.Equal(data.Point{
		Longitude: 120.89333,
		Latitude:  50.1299,
	}, places[1].Position)

	places, err = s.db.SearchForPlaces("2", 0)
	s.NoError(err)
	s.Len(places, 1)
}

// TODO add more tests for ApproveOutingStep
// TODO add more tests for DeleteOutingSteps
// TODO add more tests for DeleteOutingStep
