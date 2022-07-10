package data

import (
	"fmt"
	"os"
	"path"
	"runtime"
	"sort"
	"time"

	"github.com/juju/errors"
	"github.com/samber/lo"
	"go.uber.org/zap"
	"gorm.io/gorm/clause"
	"moul.io/zapgorm2"

	"github.com/google/uuid"
	"github.com/jackc/pgconn"
	"github.com/jackc/pgerrcode"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"planlah.sg/backend/utils"
)

var dbConn utils.Lazy[gorm.DB]

var (
	EntityNotFound      = errors.New("entity not found")
	UsernameExists      = errors.New("username taken")
	FirebaseUidExists   = errors.New("firebase uid taken")
	UserAlreadyInGroup  = errors.New("user is already in group")
	FriendRequestExists = errors.New("friend request exists")
	IsSameUser          = errors.New("users are the same")
	NotFriend           = errors.New("users are not friends")
	DMAlreadyExists     = errors.New("dm already exists")
)
var pageCount uint = 10

// NewDatabaseConnection Creates a new database connection
func NewDatabaseConnection(config *utils.Config, logger *zap.Logger) (*gorm.DB, error) {
	// TODO should this really be a singleton?
	return dbConn.LazyFallibleValue(func() (*gorm.DB, error) {
		dsn := fmt.Sprintf("host=%s user=%s password=%s",
			config.DatabaseHost,
			config.DatabaseUser,
			config.DatabasePassword,
		)
		pg := postgres.Open(dsn)

		dblogger := zapgorm2.New(logger)
		dblogger.SetAsDefault() // use zap logger for callbacks
		dbconfig := gorm.Config{
			Logger: dblogger,
		}

		db, err := gorm.Open(pg, &dbconfig)
		if err != nil {
			return nil, errors.Annotate(err, "opening db")
		}

		err = db.Exec(`CREATE EXTENSION IF NOT EXISTS postgis;`).Error
		if err != nil {
			return nil, errors.Annotate(err, "use postgis extension")
		}

		err = db.Exec(`drop type if exists friend_request_status;
			create type friend_request_status as enum('approved', 'pending', 'rejected');`).Error
		if err != nil {
			return nil, errors.Annotate(err, "create friend_request_status enum")
		}

		// add tables here
		models := []interface{}{
			&User{},
			&FriendRequest{},
			&Group{},
			// &Place{}, recommender will fill up Places table
			&GroupInvite{},
			&GroupMember{},
			&Message{},
			&Outing{},
			&OutingStep{},
			&OutingStepVote{},
			&Post{},
		}

		// Neat trick to migrate models with complex relationships, run auto migrations once
		// with DisableForeignKeyConstraintWhenMigrating=true to create the tables without relationships,
		// then run auto migrations with DisableForeignKeyConstraintWhenMigrating=false to build up the relationships

		// Sometimes I fear my own madness ...
		db.DisableForeignKeyConstraintWhenMigrating = true
		err = db.AutoMigrate(models...)
		if err != nil {
			return nil, errors.Annotate(err, "migrating db without fks")
		}
		db.DisableForeignKeyConstraintWhenMigrating = false
		err = db.AutoMigrate(models...)
		if err != nil {
			return nil, errors.Annotate(err, "migrating db with fks")
		}

		sqlDB, err := db.DB()
		if err != nil {
			return nil, errors.Annotate(err, "getting raw db")
		}

		if config.AppMode == utils.Dev || config.AppMode == utils.Orbital {
			_, filename, _, _ := runtime.Caller(0)
			sql, err := os.ReadFile(path.Join(path.Dir(filename), "dev.sql"))
			if err != nil {
				return nil, errors.Annotate(err, "reading dev.sql")
			}
			err = db.Exec(string(sql)).Error
			if err != nil {
				return nil, errors.Annotate(err, "migrate using dev.sql script")
			}
		}

		sqlDB.SetConnMaxLifetime(time.Hour)

		return db, nil
	})
}

type Database struct {
	conn   *gorm.DB
	logger *zap.Logger
}

// NewDatabase Create a new database
func NewDatabase(conn *gorm.DB) *Database {
	return &Database{conn: conn}
}

func isUniqueViolation(err error, rel string) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == pgerrcode.UniqueViolation && pgErr.ConstraintName == rel {
		return true
	}
	return false
}

func fkViolation(err error, rel string) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == pgerrcode.ForeignKeyViolation && pgErr.ConstraintName == rel {
		return true
	}
	return false
}

func isNotFoundInDb(err error) bool {
	return errors.Is(err, gorm.ErrRecordNotFound)
}

// CreateUser Creates a new User if they do not already exist.
//
// Throws UsernameExists when a User with that username already exists.
// Throws FirebaseUidExists when a User with the same Firebase UID exists.
func (db *Database) CreateUser(user *User) error {
	err := db.conn.Create(user).Error

	if err != nil {
		if isUniqueViolation(err, "users_username_key") {
			return UsernameExists
		} else if isUniqueViolation(err, "users_firebase_uid_key") {
			return FirebaseUidExists
		}
		return errors.Trace(err)
	}

	return nil
}

// GetUserByFirebaseUid Gets a User given a unique Firebase UID. Only the ID field is populated.
//
// Throws EntityNotFound when User is not found
func (db *Database) GetUserByFirebaseUid(firebaseUid string) (User, error) {
	var user User

	err := db.conn.Where(&User{FirebaseUid: firebaseUid}).
		Select("ID").First(&user).Error

	if err != nil {
		if isNotFoundInDb(err) {
			return User{}, EntityNotFound
		}
		return User{}, errors.Trace(err)
	}
	return user, nil
}

// GetUser Gets a User by their ID
//
// Throws EntityNotFound when User is not found
func (db *Database) GetUser(id uint) (User, error) {
	var user User
	err := db.conn.First(&user, id).Error
	if err != nil {
		if isNotFoundInDb(err) {
			return User{}, EntityNotFound
		}
		return User{}, errors.Trace(err)
	}
	return user, nil
}

var friendSql = `(
	select from_id from friend_requests where to_id = @thisUserId and status = 'approved' union
	select to_id from friend_requests where from_id = @thisUserId and status = 'approved'
)`

// IsFriend Checks if these users are friends
func (db *Database) IsFriend(user1 uint, user2 uint) (bool, error) {
	var req FriendRequest
	err := db.conn.Model(&FriendRequest{}).
		Where(&FriendRequest{Status: Approved}).
		Where("(from_id = @user1 and to_id = @user2) or (to_id = @user1 and from_id = @user2)",
			map[string]interface{}{"user1": user1, "user2": user2}).
		First(&req).
		Error
	if err != nil {
		if isNotFoundInDb(err) {
			return false, nil
		}
		return false, errors.Trace(err)
	}
	return true, nil
}

// SearchForFriends Search for friends (users not already friends of the current User) who have name/username
// matching the query, with pagination
func (db *Database) SearchForFriends(userId uint, query string, page uint) ([]User, error) {
	var users []User
	// this query makes it slightly ex since we might have a lot of results
	err := db.conn.Model(&User{}).
		Where("name like '%' || @q || '%' OR username like '%' || @q || '%'", map[string]interface{}{"q": query}).
		Where("id not in "+friendSql, map[string]interface{}{"thisUserId": userId}).
		Order("username,name asc").
		Limit(int(pageCount)).
		Offset(int(page * pageCount)).
		Find(&users).
		Error
	if err != nil {
		return nil, errors.Trace(err)
	}
	return users, nil
}

// SendFriendRequest Send a friend request to another user. If that user has also a friend request,
// this friend request is auto accepted.
//
// Throws FriendRequestExists when there is already a friend request from this user to the other user.
// Throws EntityNotFound when the other user does not exist.
func (db *Database) SendFriendRequest(fromUserId uint, toUserId uint) (FriendRequestStatus, error) {
	if fromUserId == toUserId {
		return Pending, IsSameUser
	}
	// accept an existing friend request from the other user
	res := db.conn.Model(&FriendRequest{}).
		Where(&FriendRequest{
			FromID: toUserId,
			ToID:   fromUserId,
		}).
		Updates(&FriendRequest{Status: Approved})
	affected := res.RowsAffected
	err := res.Error
	if err != nil {
		return Pending, errors.Annotate(err, "update prev friend req")
	}
	if affected == 1 {
		return Approved, nil
	}

	// create new friend request
	err = db.conn.Create(&FriendRequest{
		FromID: fromUserId,
		ToID:   toUserId,
		Status: Pending,
	}).Error

	if err != nil {
		if isUniqueViolation(err, "friend_requests_pkey") {
			return Pending, FriendRequestExists
		}
		if fkViolation(err, "fk_friend_requests_to") {
			return Pending, EntityNotFound
		}
		return Pending, errors.Annotate(err, "create new friend req")
	}

	return Pending, nil
}

// ApproveFriendRequest Approves a friend request. The friend request's previous status does not matter.
// If the friend request is not found, no error is thrown.
func (db *Database) ApproveFriendRequest(fromUserId uint, toUserId uint) error {
	res := db.conn.Model(&FriendRequest{}).
		Where(&FriendRequest{
			FromID: fromUserId,
			ToID:   toUserId,
		}).
		Updates(&FriendRequest{Status: Approved})
	err := res.Error
	if err != nil {
		return errors.Trace(err)
	}
	return nil
}

// RejectFriendRequest Rejects a friend request. The friend request's previous status must be pending.
// If the friend request is not found, no error is thrown.
func (db *Database) RejectFriendRequest(fromUserId uint, toUserId uint) error {
	res := db.conn.Model(&FriendRequest{}).
		Where(&FriendRequest{
			FromID: fromUserId,
			ToID:   toUserId,
			Status: Pending,
		}).
		Updates(&FriendRequest{Status: Rejected})
	err := res.Error
	if err != nil {
		return errors.Trace(err)
	}
	return nil
}

// PendingFriendRequests Lists all pending friend requests
func (db *Database) PendingFriendRequests(userId uint, page uint) ([]FriendRequest, error) {
	var reqs []FriendRequest
	err := db.conn.Model(&FriendRequest{}).
		Preload("From").
		Where(&FriendRequest{
			ToID:   userId,
			Status: Pending,
		}).
		Find(&reqs).
		Offset(int(page * pageCount)).
		Limit(int(pageCount)).
		Error
	if err != nil {
		return nil, errors.Trace(err)
	}
	return reqs, nil
}

// ListFriends Lists all users who are friends of the current user
func (db *Database) ListFriends(userId uint, page uint) ([]User, error) {
	var users []User

	err := db.conn.Raw(`
SELECT u.*
FROM users AS u
INNER JOIN
(
	SELECT from_id
	FROM friend_requests
	WHERE to_id = ?
	AND status = 'approved'
	UNION
	SELECT to_id
	FROM friend_requests
	WHERE from_id = ?
	AND status = 'approved'
) AS friend_id
ON u.id = friend_id.from_id
LIMIT ? OFFSET ?`, userId, userId, pageCount, page*pageCount).
		Scan(&users).
		Error

	if err != nil {
		return nil, errors.Trace(err)
	}
	return users, nil
}

func (db *Database) getUnreadMessagesCountForGroups(userId uint, groupIds []uint) (map[uint]uint, error) {
	type unreadMessagesCountByGroup struct {
		UnreadMessagesCount uint
		GroupID             uint
	}

	var counts []unreadMessagesCountByGroup

	// this can be made better definitely
	err := db.conn.Table("messages m").
		Select("COUNT(m.id) AS unread_messages_count, bygm.group_id AS group_id").
		Joins("INNER JOIN group_members bygm ON bygm.id = m.by_id").
		Joins(`INNER JOIN group_members gm ON gm.group_id = bygm.group_id AND gm.user_id = ? AND 
			(gm.last_seen_message_id IS NULL OR m.sent_at > (select lm.sent_at from messages lm where lm.id = gm.last_seen_message_id))`, userId).
		Group("bygm.group_id").
		Having("bygm.group_id IN ?", groupIds).
		Find(&counts).
		Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	countMap := make(map[uint]uint)
	for _, c := range counts {
		countMap[c.GroupID] = c.UnreadMessagesCount
	}

	return countMap, nil
}

func (db *Database) getLastMessagesForGroups(groupIds []uint) (map[uint]Message, error) {
	type lastMessage struct {
		Message
		GroupID uint
	}

	var messages []lastMessage

	err := db.conn.Table("messages").
		Preload("By").
		Preload("By.User").
		Select("distinct on (group_id) messages.*, group_members.group_id").
		Joins("inner join group_members ON group_members.id = by_id").
		Where("group_id in ?", groupIds).
		Order("group_id, sent_at desc").
		Find(&messages).
		Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	lastMessages := make(map[uint]Message)
	for _, last := range messages {
		lastMessages[last.GroupID] = last.Message
	}

	return lastMessages, nil
}

type GroupInfo struct {
	Group
	UnreadMessageCount uint
	LastMessage        *Message
}

// assumes the groupIds are already DM groupIds
func (db *Database) loadDMOtherUserInfo(userId uint, groupIds []uint) (map[uint]User, error) {
	type otherUserInfo struct {
		GroupID uint
		User
	}
	var others []otherUserInfo
	err := db.conn.Table("group_members gm").
		Joins("inner join users u ON u.id = gm.user_id and u.id <> ?", userId).
		Where("gm.group_id in ?", groupIds).
		Select("gm.group_id, u.*").
		Find(&others).
		Error
	if err != nil {
		return nil, errors.Trace(err)
	}

	othersMap := make(map[uint]User)
	for _, other := range others {
		othersMap[other.GroupID] = other.User
	}

	return othersMap, nil
}

func (db *Database) toGroupInfos(userId uint, groups []Group) ([]GroupInfo, error) {
	groupIds := lo.Map(groups, func(g Group, _ int) uint {
		return g.ID
	})

	unreads, err := db.getUnreadMessagesCountForGroups(userId, groupIds)
	if err != nil {
		return nil, errors.Trace(err)
	}

	lastMsgs, err := db.getLastMessagesForGroups(groupIds)
	if err != nil {
		return nil, errors.Trace(err)
	}

	dmGroupIds := lo.FilterMap(groups, func(t Group, i int) (uint, bool) {
		if t.IsDM {
			return t.ID, true
		}
		return 0, false
	})
	otherUserDMGroups, err := db.loadDMOtherUserInfo(userId, dmGroupIds)
	if err != nil {
		return nil, errors.Trace(err)
	}

	groupInfos := lo.Map(groups, func(g Group, _ int) GroupInfo {
		var lastMsg *Message
		if msg, ok := lastMsgs[g.ID]; ok {
			lastMsg = &msg
		} else {
			lastMsg = nil
		}
		if g.IsDM {
			otherUser := otherUserDMGroups[g.ID]
			g.Name = otherUser.Name
			g.Description = ""
			g.ImageLink = otherUser.ImageLink
		}
		return GroupInfo{
			Group:              g,
			UnreadMessageCount: unreads[g.ID],
			LastMessage:        lastMsg,
		}
	})

	return groupInfos, nil
}

// GetAllGroups Gets all Group of a User
func (db *Database) GetAllGroups(userId uint) ([]GroupInfo, error) {
	var groups []Group
	err := db.conn.Model(&GroupMember{}).
		Where(&GroupMember{UserID: userId}).
		Joins("inner join groups g ON g.id = group_id").
		Select("g.*").
		Find(&groups).Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	groupInfos, err := db.toGroupInfos(userId, groups)
	return groupInfos, errors.Trace(err)
}

// GetGroup Gets the Group by ID.
//
// This method is intended to get information about _any_ arbitrary Group,
// even those the User is not joined into. If such groups exist, then their
// LastMessage and UnreadMessagesCount are not initialized
//
// Throws EntityNotFound when Group is not found.
func (db *Database) GetGroup(userId uint, groupId uint) (GroupInfo, error) {
	var group Group
	err := db.conn.Model(&Group{}).Where("id = ?", groupId).First(&group).Error

	if err != nil {
		if isNotFoundInDb(err) {
			return GroupInfo{}, EntityNotFound
		}
		return GroupInfo{}, errors.Trace(err)
	}

	groupInfos, err := db.toGroupInfos(userId, []Group{group})
	if err != nil {
		return GroupInfo{}, errors.Trace(err)
	}
	return groupInfos[0], nil
}

// AddUserToGroup Adds a User to a Group and returns the GroupMember relationship
//
// Throws UserAlreadyInGroup if the User is already in this Group
func (db *Database) AddUserToGroup(userId uint, grpId uint) (GroupMember, error) {
	// TODO set last seen message id?
	grpMember := GroupMember{GroupID: grpId, UserID: userId}
	err := db.conn.Omit("LastSeenMessageID").Create(&grpMember).Error

	if err != nil {
		if isUniqueViolation(err, "composite_grp_member_idx") {
			return GroupMember{}, UserAlreadyInGroup
		}
		return GroupMember{}, errors.Trace(err)
	}

	return grpMember, nil
}

// RemoveUserFromGroup Removes a User from a Group
func (db *Database) RemoveUserFromGroup(userId uint, grpId uint) error {

	grpMember := GroupMember{GroupID: grpId, UserID: userId}
	err := db.conn.Delete(grpMember).Error

	if err != nil {
		return errors.Trace(err)
	}

	return nil
}

// GetGroupMember Gets the GroupMember of the User and Group.
func (db *Database) GetGroupMember(userId uint, groupId uint) (*GroupMember, error) {
	var grpMember GroupMember
	err := db.conn.Where(&GroupMember{UserID: userId, GroupID: groupId}).First(&grpMember).Error
	if err != nil {
		if isNotFoundInDb(err) {
			return nil, nil
		}
		return nil, errors.Trace(err)
	}
	return &grpMember, nil
}

// CreateGroup Creates a Group
func (db *Database) CreateGroup(group *Group) error {
	return errors.Trace(db.conn.Omit("OwnerID", "ActiveOutingID").Create(group).Error)
}

// CreateDMGroup Creates a DM Group
//
// Throws NotFriend if the Users are not friends.
// Throws DMAlreadyExists if there exists a DM Group between the two users.
func (db *Database) CreateDMGroup(userId uint, otherUserId uint) (Group, error) {
	if v, err := db.IsFriend(userId, otherUserId); err == nil && !v {
		return Group{}, NotFriend
	} else if err != nil {
		return Group{}, errors.Annotate(err, "IsFriend failed")
	}

	var c int64
	err := db.conn.Table("group_members gm").
		Where("gm.user_id = ? or gm.user_id = ?", userId, otherUserId).
		Group("gm.group_id").
		Having("count(gm) = 2 and true = (select is_dm from groups where id = gm.group_id)").
		Count(&c).Error

	if err != nil {
		return Group{}, errors.Trace(err)
	}
	if c == 1 {
		return Group{}, DMAlreadyExists
	}

	group := Group{
		IsDM: true,
	}
	err = db.conn.Omit("OwnerID", "ActiveOutingID").Create(&group).Error
	if err != nil {
		return Group{}, errors.Trace(err)
	}

	_, err = db.AddUserToGroup(userId, group.ID)
	if err != nil {
		return Group{}, errors.Trace(err)
	}

	_, err = db.AddUserToGroup(otherUserId, group.ID)
	if err != nil {
		return Group{}, errors.Trace(err)
	}

	return group, nil
}

// UpdateGroupOwner Updates the Group owner.
//
// Does not check if the new owner is a GroupMember of this Group.
func (db *Database) UpdateGroupOwner(groupID uint, ownerID uint) error {
	return errors.Trace(db.conn.Where(&Group{ID: groupID}).Updates(&Group{OwnerID: ownerID}).Error)
}

// CreateMessage Creates a Message
func (db *Database) CreateMessage(msg *Message) error {
	return errors.Trace(db.conn.Create(msg).Error)
}

// SetLastSeenMessageIDIfNewer Sets the LastSeenMessageID of the GroupMember if it's newer.
// The GroupMember is derived from the Group the Message belongs to (via transitive By relationship)
// and the User given in the parameters.
//
// Does nothing if such a GroupMember is not found (Message is not in any Groups of the User), or if
// the Message itself is not found.
func (db *Database) SetLastSeenMessageIDIfNewer(userId uint, messageId uint) error {
	err := db.conn.Exec(
		`UPDATE group_members AS gm SET last_seen_message_id = @messageId WHERE gm.user_id = @userId and gm.group_id =
				(select by.group_id from group_members by where by.id = 
					(select m.by_id from messages m where m.id = @messageId and
						((m.sent_at > (select l.sent_at from messages l where l.id = gm.last_seen_message_id)) OR (gm.last_seen_message_id IS NULL))
					)
				)`,
		map[string]interface{}{
			"messageId": messageId,
			"userId":    userId,
		}).
		Error
	return errors.Trace(err)
}

// GetMessagesRelative Gets {count} number of Messages relative (before or after) to the given cursor Message,
// assuming the Message is from a Group that the User is in.
//
// Throws EntityNotFound if the Message itself is not found.
func (db *Database) GetMessagesRelative(userId uint, messageId uint, count uint, before bool) ([]Message, error) {
	var msg Message
	var messages []Message

	var comparison string
	var orderby string

	if before {
		comparison = "<="
		orderby = "desc"
	} else {
		comparison = ">="
		orderby = "asc"
	}

	err := db.conn.Model(&Message{}).
		Where(`id = ? and by_id in (select id from group_members where group_id in 
			(select group_id from group_members where user_id = ?))`, messageId, userId).
		First(&msg).Error

	if err != nil {
		if isNotFoundInDb(err) {
			return nil, EntityNotFound
		}
		return nil, errors.Trace(err)
	}

	// Goddamn Gorm doesn't let you orderby, limit, then orderby again
	// so instead we have no manually sort the messages ourselves
	err = db.conn.Model(&Message{}).
		Preload("By").
		Preload("By.User").
		Where(fmt.Sprintf(`sent_at %s ? and by_id in (select id from group_members where group_id = 
			(select group_id from group_members where id = ?))`, comparison), msg.SentAt, msg.ByID).
		Order("sent_at " + orderby).
		Limit(int(count)).
		// Order("sent_at asc").
		Find(&messages).
		Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	// manually sort
	sort.Slice(messages, func(i, j int) bool {
		return messages[i].SentAt.Before(messages[j].SentAt)
	})

	return messages, nil
}

// GetMessages Gets Message within a time range
func (db *Database) GetMessages(groupId uint, start time.Time, end time.Time) ([]Message, error) {
	var messages []Message

	err := db.conn.
		Table("messages").
		Preload("By").
		Preload("By.User").
		Joins("right join group_members on group_members.id = messages.by_id and group_members.group_id = ?", groupId).
		Where("? > messages.sent_at and messages.sent_at >= ?", end, start).
		Find(&messages).
		Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	return messages, nil
}

// CreateOuting Creates an Outing
func (db *Database) CreateOuting(outing *Outing) error {
	return errors.Trace(db.conn.Create(outing).Error)
}

// CreateOutingStep Creates an OutingStep
//
// Throws EntityNotFound when the Place referred to by PlaceID is not found
func (db *Database) CreateOutingStep(outingStep *OutingStep) error {
	err := db.conn.Create(outingStep).Error
	if err != nil {
		if fkViolation(err, "fk_outing_steps_place") {
			return EntityNotFound
		}
		return errors.Trace(err)
	}
	return nil
}

// UpsertOutingStepVote Vote for an OutingStep
//
// Does not check if the GroupMember is in the Group of this OutingStep.
// Use GetOutingAndGroupForOutingStep for that.
func (db *Database) UpsertOutingStepVote(outingStep *OutingStepVote) error {
	err := db.conn.Clauses(clause.OnConflict{
		UpdateAll: true,
	}).Create(outingStep).Error

	if err != nil {
		if isUniqueViolation(err, "fk_outing_steps_votes") {
			return EntityNotFound
		}
		return errors.Trace(err)
	}

	return nil
}

// GetOuting Gets an Outing by its ID
//
// Does not check if the User belongs to the Group belonging to the Outing
//
// Throws EntityNotFound if the Outing is not found.
func (db *Database) GetOuting(outingId uint) (Outing, error) {
	var outing Outing
	err := db.conn.Where(&Outing{ID: outingId}).
		First(&outing).
		Error

	if err != nil {
		if isNotFoundInDb(err) {
			return Outing{}, EntityNotFound
		}
		return Outing{}, errors.Trace(err)
	}

	return outing, nil
}

// GetOutingWithSteps Gets an Outing by its ID and it's OutingStep + OutingStep.Place (and OutingStepVote)
//
// Does not check if the User belongs to the Group belonging to the Outing
//
// Throws EntityNotFound if the Outing is not found.
func (db *Database) GetOutingWithSteps(outingId uint) (Outing, error) {
	var outing Outing
	err := db.conn.Where(&Outing{ID: outingId}).
		Preload("Steps").
		Preload("Steps.Place", SelectPlaces).
		Preload("Steps.Votes").
		First(&outing).
		Error

	if err != nil {
		if isNotFoundInDb(err) {
			return Outing{}, EntityNotFound
		}
		return Outing{}, errors.Trace(err)
	}

	return outing, nil
}

type OutingAndGroupID struct {
	GroupID  uint
	OutingID uint
}

// GetOutingAndGroupForOutingStep Gets the Outing ID and Group ID for an OutingStep
//
// Does not check if the User belongs to the Group belonging to the OutingStep via Outing
//
// Throws EntityNotFound if the OutingStep is not found.
func (db *Database) GetOutingAndGroupForOutingStep(outingStepId uint) (OutingAndGroupID, error) {
	var res OutingAndGroupID
	err := db.conn.Table("outing_steps os").
		Where("os.id = ?", outingStepId).
		Select("o.group_id AS group_id, o.id AS outing_id").
		Joins("inner join outings o ON o.id = os.outing_id").
		Limit(1).
		Find(&res).
		Error

	if err != nil {
		return OutingAndGroupID{}, errors.Trace(err)
	}

	// not possible to have 0 as ids: means that we didn't find the rows
	if res.OutingID == 0 && res.GroupID == 0 {
		return OutingAndGroupID{}, EntityNotFound
	}

	return res, nil
}

// GetAllOutings Gets all Outings for a Group
//
// Does not check if the User belongs to the Group or if no such Group
func (db *Database) GetAllOutings(groupId uint) ([]Outing, error) {
	var outings []Outing

	err := db.conn.Model(&Outing{}).
		Where("group_id = ?", groupId).
		Preload("Steps").
		Preload("Steps.Place", SelectPlaces).
		Preload("Steps.Votes").
		Find(&outings).
		Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	return outings, nil
}

// ApproveOutingStep Approves the outing step
func (db *Database) ApproveOutingStep(outingStepId uint) error {
	err := db.conn.Model(&OutingStep{}).Where(&OutingStep{ID: outingStepId}).
		Update("approved", true).Error
	return errors.Trace(err)
}

// DeleteOutingStep Delete the outing step with the same ID
func (db *Database) DeleteOutingStep(outingStepId uint) error {
	err := db.conn.Delete(OutingStep{}, outingStepId).Error
	return errors.Trace(err)
}

// DeleteOutingSteps Deletes outings steps with the same ID
func (db *Database) DeleteOutingSteps(outingSteps []OutingStep) error {
	err := db.conn.Delete(OutingStep{}, lo.Map(outingSteps, func(t OutingStep, _ int) uint {
		return t.ID
	})).Error
	return errors.Trace(err)
}

// GetActiveOuting Gets the active Outing for a Group
//
// Does not check if the User belongs to the Group
func (db *Database) GetActiveOuting(groupId uint) (*Outing, error) {
	var outing Outing
	err := db.conn.Model(&Outing{}).
		Preload("Steps").
		Preload("Steps.Place", SelectPlaces).
		Preload("Steps.Votes").
		Where("id = (select active_outing_id from groups where id = ?)", groupId).
		First(&outing).
		Error

	if err != nil {
		if isNotFoundInDb(err) {
			return nil, nil
		}
		return nil, errors.Trace(err)
	}
	return &outing, nil
}

// UpdateActiveOuting Sets the active Outing for a Group
//
// Does not check if the User belongs to the Group
func (db *Database) UpdateActiveOuting(groupId uint, outingId uint) error {
	return errors.Trace(db.conn.Model(&Group{}).
		Where("id = ?", groupId).
		Update("active_outing_id", outingId).
		Error)
}

// CreateGroupInvite Creates a Group Invite
func (db *Database) CreateGroupInvite(inv *GroupInvite) error {
	return errors.Trace(db.conn.Create(inv).Error)
}

// GetGroupInvites Gets all the GroupInvite for a Group
func (db *Database) GetGroupInvites(groupId uint) ([]GroupInvite, error) {
	var invites []GroupInvite

	err := db.conn.Where(&GroupInvite{GroupID: groupId, Active: true}).
		Where("expiry IS NULL OR expiry > now()").
		Find(&invites).Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	return invites, nil
}

// InvalidateInvite Sets the invite to inactive if the User belongs to this GroupInvite's Group
func (db *Database) InvalidateInvite(userId uint, inviteId uuid.UUID) error {
	return errors.Trace(db.conn.Exec(`UPDATE group_invites SET active = FALSE WHERE id = ? AND 
		group_id IN (SELECT group_id FROM group_members WHERE user_id = ?)`, inviteId, userId).Error)
}

// JoinByInvite Joins a Group by a GroupInvite
//
// Throws UserAlreadyInGroup if the User is already in this Group
func (db *Database) JoinByInvite(userId uint, inviteId uuid.UUID) (GroupInvite, error) {
	var invite GroupInvite
	err := db.conn.Model(&GroupInvite{}).
		Where(&GroupInvite{ID: inviteId, Active: true}).
		Where("expiry IS NULL OR expiry > now()").
		First(&invite).Error

	if err != nil {
		if isNotFoundInDb(err) {
			return GroupInvite{}, EntityNotFound
		}
		return GroupInvite{}, errors.Trace(err)
	}

	_, err = db.AddUserToGroup(userId, invite.GroupID)
	return invite, errors.Trace(err)
}

func SelectPlaces(tx *gorm.DB) *gorm.DB {
	return tx.Select("id, name, location, ST_AsText(position) AS position, formatted_address, image_url, about, place_type")
}

// SearchForPlaces if their name matches the query
func (db *Database) SearchForPlaces(query string, page uint) ([]Place, error) {
	var places []Place
	err := SelectPlaces(db.conn.Model(&Place{})).
		Where("name like '%' || ? || '%'", query).
		Order("name asc").
		Limit(int(pageCount)).
		Offset(int(page * pageCount)).
		Find(&places).
		Error
	if err != nil {
		return nil, errors.Trace(err)
	}
	return places, nil
}

// GetPlaces Gets places by their IDs
func (db *Database) GetPlaces(placeIds []uint) ([]Place, error) {
	var places []Place
	err := SelectPlaces(db.conn.Model(&Place{})).
		Find(&places, placeIds).
		Error
	if err != nil {
		return nil, errors.Trace(err)
	}
	return places, nil
}
