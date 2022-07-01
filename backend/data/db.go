package data

import (
	"fmt"
	"github.com/juju/errors"
	"go.uber.org/zap"
	"gorm.io/gorm/clause"
	"os"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgconn"
	"github.com/jackc/pgerrcode"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"planlah.sg/backend/utils"
)

var dbConn utils.Lazy[gorm.DB]

var (
	entityNotFound     = errors.New("entity not found")
	usernameExists     = errors.New("username taken")
	firebaseUidExists  = errors.New("firebase uid taken")
	userAlreadyInGroup = errors.New("user is already in group")
)

// NewDatabaseConnection creates a new database connection
func NewDatabaseConnection(config *utils.Config) (*gorm.DB, error) {
	// TODO should this really be a singleton?
	return dbConn.FallibleValue(func() (*gorm.DB, error) {
		dsn := fmt.Sprintf("host=%s user=%s password=%s",
			config.DatabaseHost,
			config.DatabaseUser,
			config.DatabasePassword,
		)
		pg := postgres.Open(dsn)
		dbconfig := gorm.Config{}

		db, err := gorm.Open(pg, &dbconfig)
		if err != nil {
			return nil, errors.Annotate(err, "opening db")
		}

		// add tables here
		models := []interface{}{&User{}, &Group{}, &GroupInvite{}, &GroupMember{}, &Message{}, &Outing{}, &OutingStep{}, &OutingStepVote{}}

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
			sql, err := os.ReadFile("./data/dev.sql")
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

// NewDatabase create a new database
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

func isNotFoundInDb(err error) bool {
	return errors.Is(err, gorm.ErrRecordNotFound)
}

func (db *Database) handleDbError(err error) error {
	db.logger.Fatal("db", zap.Error(err))
	return err
}

// CreateUser creates a new user and checks if there already exists a user
func (db *Database) CreateUser(user *User) error {
	err := db.conn.Create(user).Error

	if err != nil {
		if isUniqueViolation(err, "users_username_key") {
			return usernameExists
		} else if isUniqueViolation(err, "users_firebase_uid_key") {
			return firebaseUidExists
		}
		return db.handleDbError(err)
	}

	return nil
}

// GetUserByFirebaseUid gets a user given a unique firebaseUid
func (db *Database) GetUserByFirebaseUid(firebaseUid string) (User, error) {
	var user User

	err := db.conn.Where(&User{FirebaseUid: firebaseUid}).
		Select("ID").First(&user).Error

	if err != nil {
		if isNotFoundInDb(err) {
			return User{}, entityNotFound
		}
		return User{}, db.handleDbError(err)
	}
	return user, nil
}

func (db *Database) GetUser(id uint) (User, error) {
	var user User
	err := db.conn.First(&user, id).Error
	if err != nil {
		if isNotFoundInDb(err) {
			return User{}, entityNotFound
		}
		return User{}, db.handleDbError(err)
	}
	return user, nil
}

func (db *Database) GetAllGroups(userId uint) ([]GroupMember, error) {
	var groupMembers []GroupMember
	err := db.conn.Joins("Group").Find(&groupMembers, "group_members.user_id = ?", userId).Error

	if err != nil {
		return nil, db.handleDbError(err)
	}

	return groupMembers, nil
}

// GetGroup This method is intended to get information about _any_ arbitrary group,
// even those the user is not joined into
func (db *Database) GetGroup(groupId uint) (Group, error) {
	var group Group
	err := db.conn.Model(&Group{}).Where("id = ?", groupId).First(&group).Error

	if err != nil {
		if isNotFoundInDb(err) {
			return Group{}, entityNotFound
		}
		return Group{}, db.handleDbError(err)
	}
	return group, nil
}

func (db *Database) AddUserToGroup(userId uint, grpId uint) (GroupMember, error) {
	// TODO set last seen message id?
	grpMember := GroupMember{GroupID: grpId, UserID: userId}
	err := db.conn.Omit("LastSeenMessageID").Create(&grpMember).Error

	if err != nil {
		if isUniqueViolation(err, "composite_grp_member_idx") {
			return GroupMember{}, userAlreadyInGroup
		}
		return GroupMember{}, db.handleDbError(err)
	}

	return grpMember, err
}

func (db *Database) GetGroupMember(userId uint, groupId uint) (GroupMember, error) {
	var grpMember GroupMember
	err := db.conn.Where(&GroupMember{UserID: userId, GroupID: groupId}).First(&grpMember).Error
	if err != nil {
		if isNotFoundInDb(err) {
			return GroupMember{}, entityNotFound
		}
		return GroupMember{}, db.handleDbError(err)
	}
	return grpMember, nil
}

func (db *Database) CreateGroup(group *Group) error {
	return db.handleDbError(db.conn.Omit("OwnerID", "ActiveOutingID").Create(group).Error)
}

// UpdateGroupOwner Updates the group owner. Does not check if the new owner is a GroupMember of this Group.
func (db *Database) UpdateGroupOwner(groupID uint, ownerID uint) error {
	return db.handleDbError(db.conn.Model(&Group{ID: groupID}).Update("OwnerID", ownerID).Error)
}

func (db *Database) CreateMessage(msg *Message) error {
	return db.handleDbError(db.conn.Create(msg).Error)
}

// SetLastSeenMessageIDIfNewer Sets the LastSeenMessageID if it's newer, for this GroupMember in the same group the message
// exists in and for this User. This does nothing if the message is not in any groups of the user.
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
	return db.handleDbError(err)
}

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
			return nil, entityNotFound
		}
		return nil, db.handleDbError(err)
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
		return nil, db.handleDbError(err)
	}

	// manually sort
	sort.Slice(messages, func(i, j int) bool {
		return messages[i].SentAt.Before(messages[j].SentAt)
	})

	return messages, nil
}

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
		return nil, db.handleDbError(err)
	}

	return messages, nil
}

type LastMessage struct {
	Message
	GroupID uint
}

type UnreadMessagesCountByGroup struct {
	UnreadMessagesCount uint
	GroupID             uint
}

func (db *Database) GetUnreadMessagesCountForGroups(userId uint, groupIds []uint) (map[uint]uint, error) {
	var counts []UnreadMessagesCountByGroup

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
		return nil, db.handleDbError(err)
	}

	countMap := make(map[uint]uint)
	for _, c := range counts {
		countMap[c.GroupID] = c.UnreadMessagesCount
	}

	return countMap, nil
}

func (db *Database) GetLastMessagesForGroups(groupIds []uint) (map[uint]Message, error) {
	var messages []LastMessage

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
		return nil, db.handleDbError(err)
	}

	lastMessages := make(map[uint]Message)
	for _, last := range messages {
		lastMessages[last.GroupID] = last.Message
	}

	return lastMessages, nil
}

func (db *Database) CreateOuting(outing *Outing) error {
	return db.handleDbError(db.conn.Create(outing).Error)
}

func (db *Database) CreateOutingStep(outingStep *OutingStep) error {
	return db.handleDbError(db.conn.Create(outingStep).Error)
}

func (db *Database) UpsertOutingStepVote(outingStep *OutingStepVote) error {
	err := db.conn.Clauses(clause.OnConflict{
		UpdateAll: true,
	}).Create(outingStep).Error

	if err != nil {
		if isUniqueViolation(err, "fk_outing_steps_votes") {
			return entityNotFound
		}
		return db.handleDbError(err)
	}

	return nil
}

func (db *Database) GetOuting(outingId uint) (Outing, error) {
	var outing Outing
	err := db.conn.Model(&Outing{ID: outingId}).
		First(&outing).
		Error

	if err != nil {
		if isNotFoundInDb(err) {
			return Outing{}, entityNotFound
		}
		return Outing{}, db.handleDbError(err)
	}

	return outing, nil
}

type OutingAndGroupID struct {
	GroupID  uint
	OutingID uint
}

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
		return OutingAndGroupID{}, db.handleDbError(err)
	}

	// not possible to have 0 as ids: means that we didn't find the rows
	if res.OutingID == 0 && res.GroupID == 0 {
		return OutingAndGroupID{}, entityNotFound
	}

	return res, nil
}

func (db *Database) GetAllOutings(groupId uint) ([]Outing, error) {
	var outings []Outing

	err := db.conn.Model(&Outing{}).
		Where("group_id = ?", groupId).
		Preload("Steps").
		Preload("Steps.Votes").
		Find(&outings).
		Error

	if err != nil {
		return nil, db.handleDbError(err)
	}

	return outings, nil
}

func (db *Database) GetActiveOuting(groupId uint) (Outing, error) {
	var outing Outing
	err := db.conn.Model(&Outing{}).
		Where("id = (select active_outing_id from groups where id = ?)", groupId).
		Preload("Steps").
		Preload("Steps.Votes").
		First(&outing).
		Error

	if err != nil {
		if isNotFoundInDb(err) {
			return Outing{}, entityNotFound
		}
		return Outing{}, db.handleDbError(err)
	}
	return outing, nil
}

func (db *Database) UpdateActiveOuting(groupId uint, outingId uint) error {
	return db.handleDbError(db.conn.Model(&Group{}).
		Where("id = ?", groupId).
		Update("active_outing_id", outingId).
		Error)
}

func (db *Database) CreateGroupInvite(inv *GroupInvite) error {
	return db.handleDbError(db.conn.Create(inv).Error)
}

func (db *Database) GetGroupInvites(groupId uint) ([]GroupInvite, error) {
	var invites []GroupInvite

	err := db.conn.Model(&GroupInvite{GroupID: groupId, Active: true}).
		Where("expiry IS NULL OR expiry > now()").
		Find(&invites).Error

	if err != nil {
		return nil, db.handleDbError(err)
	}

	return invites, nil
}

func (db *Database) InvalidateInvite(userId uint, inviteId uuid.UUID) error {
	return db.handleDbError(db.conn.Exec(`UPDATE group_invites SET active = FALSE WHERE id = ? AND 
		group_id IN (SELECT group_id FROM group_members WHERE user_id = ?)`, inviteId, userId).Error)
}

func (db *Database) JoinByInvite(userId uint, inviteId uuid.UUID) (GroupInvite, error) {
	var invite GroupInvite
	err := db.conn.Table("group_invites gi").
		Where("gi.id = ? AND gi.active = TRUE", inviteId).
		Where("gi.expiry IS NULL OR gi.expiry > now()").
		First(&invite).Error

	if err != nil {
		return GroupInvite{}, db.handleDbError(err)
	}

	_, err = db.AddUserToGroup(userId, invite.GroupID)
	return invite, db.handleDbError(err)
}
