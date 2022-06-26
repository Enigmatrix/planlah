package data

import (
	"errors"
	"fmt"
	"gorm.io/gorm/clause"
	"log"
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
			return nil, errors.New(fmt.Sprintf("cannot open db: %v", err))
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
			return nil, errors.New(fmt.Sprintf("error while migrating db without fks: %v", err))
		}
		db.DisableForeignKeyConstraintWhenMigrating = false
		err = db.AutoMigrate(models...)
		if err != nil {
			return nil, errors.New(fmt.Sprintf("error while migrating db with fks: %v", err))
		}

		sqlDB, err := db.DB()
		if err != nil {
			return nil, errors.New(fmt.Sprintf("error getting raw db: %v", err))
		}

		if config.AppMode == utils.Dev || config.AppMode == utils.Orbital {
			sql, err := os.ReadFile("./data/dev.sql")
			if err != nil {
				return nil, errors.New(fmt.Sprintf("err while reading dev.sql: %v", err))
			}
			err = db.Exec(string(sql)).Error
			if err != nil {
				return nil, errors.New(fmt.Sprintf("err while running dev.sql migration: %v", err))
			}
		}

		sqlDB.SetConnMaxLifetime(time.Hour)

		return db, nil
	})
}

type Database struct {
	conn *gorm.DB
}

// NewDatabase create a new database
func NewDatabase(conn *gorm.DB) *Database {
	return &Database{conn: conn}
}

// CreateUser creates a new user and checks if there already exists a user
func (db *Database) CreateUser(user *User) error {
	err := db.conn.Create(user).Error

	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgerrcode.UniqueViolation {
			return errors.New("user already exists")
		}
	}

	return nil
}

// GetUserByFirebaseUid gets a user given a unique firebaseUid
func (db *Database) GetUserByFirebaseUid(firebaseUid string) *User {
	var user User

	err := db.conn.Where(&User{FirebaseUid: firebaseUid}).
		Select("ID").First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}

	return &user
}

func (db *Database) GetUser(id uint) *User {
	var user User
	err := db.conn.First(&user, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}
	return &user
}

func (db *Database) GetAllGroups(userId uint) []GroupMember {
	var groupMembers []GroupMember
	err := db.conn.Joins("Group").Find(&groupMembers, "group_members.user_id = ?", userId).Error

	if err != nil {
		return nil
	}
	return groupMembers
}

func (db *Database) AddUserToGroup(userId uint, grpId uint) (*GroupMember, error) {
	// TODO set last seen message id?
	grpMember := GroupMember{GroupID: grpId, UserID: userId}
	err := db.conn.Omit("LastSeenMessageID").Create(&grpMember).Error

	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgerrcode.UniqueViolation {
			return nil, errors.New(fmt.Sprintf("user is already in group %d", grpId))
		}
	}

	return &grpMember, err
}

func (db *Database) GetGroupMember(userId uint, groupId uint) *GroupMember {
	var grpMember GroupMember
	err := db.conn.Where(&GroupMember{UserID: userId, GroupID: groupId}).First(&grpMember).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}
	return &grpMember
}

func (db *Database) CreateGroup(group *Group) error {
	return db.conn.Omit("OwnerID").Create(group).Error
}

func (db *Database) UpdateGroupOwner(groupID uint, ownerID uint) error {
	return db.conn.Model(&Group{ID: groupID}).Update("OwnerID", ownerID).Error
}

func (db *Database) CreateMessage(msg *Message) error {
	return db.conn.Create(msg).Error
}

func (db *Database) SetLastSeenMessageIDIfNewer(userId uint, messageId uint) {
	// this does nothing if the message is not the same group as the group_member as well :)
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
	if err != nil {
		log.Fatalf("error in updating last_seen_message_id: %v", err)
	}
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
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("message is not in any of the user's groups")
		}
		log.Fatalf("get message before (get message) failed: %v", err)
		return nil, nil
	}
	// TODO goddamn Gorm doesn't let you orderby, limit, then orderby again
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
		log.Fatalf("get message before (query) failed: %v", err)
		return nil, nil
	}

	sort.Slice(messages, func(i, j int) bool {
		return messages[i].SentAt.Before(messages[j].SentAt)
	})

	return messages, nil
}

func (db *Database) GetMessages(groupId uint, start time.Time, end time.Time) []Message {
	var messages []Message

	// Use preload instead of join since the numbers of users/group_members loaded will be small
	// and the extra 2 sql statements executed will be cheap (ignoring latency)

	// This is an acceptable but lazy solution, of course, sourced from the horrible documentation of gorm.
	// However, once a better join solution (that loads the foreign table properties) exists, we should
	// use that
	err := db.conn.
		Table("messages").
		Preload("By").
		Preload("By.User").
		Joins("right join group_members on group_members.id = messages.by_id and group_members.group_id = ?", groupId).
		Where("? > messages.sent_at and messages.sent_at >= ?", end, start).
		Find(&messages).
		Error

	if err != nil {
		return nil
	}
	return messages
}

type LastMessage struct {
	Message
	GroupID uint
}

type UnreadMessagesCountByGroup struct {
	UnreadMessagesCount uint
	GroupID             uint
}

func (db *Database) GetUnreadMessagesCountForGroups(userId uint, groupIds []uint) map[uint]uint {
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
		log.Fatalf("error in GetUnreadMessagesCountForGroups: %v", err)
		return nil
	}

	countMap := make(map[uint]uint)
	for _, c := range counts {
		countMap[c.GroupID] = c.UnreadMessagesCount
	}

	return countMap
}

func (db *Database) GetLastMessagesForGroups(groupIds []uint) map[uint]Message {
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
		log.Fatalf("error in GetLastMessagesForGroups: %v", err)
		return nil
	}

	lastMessages := make(map[uint]Message)
	for _, last := range messages {
		lastMessages[last.GroupID] = last.Message
	}

	return lastMessages
}

func (db *Database) CreateOuting(outing *Outing) error {
	return db.conn.Create(outing).Error
}

func (db *Database) CreateOutingStep(outingStep *OutingStep) error {
	return db.conn.Create(outingStep).Error
}

func (db *Database) UpsertOutingStepVote(outingStep *OutingStepVote) error {
	err := db.conn.Clauses(clause.OnConflict{
		UpdateAll: true,
	}).Create(outingStep).Error

	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgerrcode.ForeignKeyViolation && pgErr.ConstraintName == "fk_outing_steps_votes" {
			return fmt.Errorf("outing steps does not exist")
		}
		return err
	}

	return nil
}

func (db *Database) GetOuting(outingId uint) *Outing {
	var outing Outing
	err := db.conn.Model(&Outing{ID: outingId}).
		First(&outing).
		Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil
		}
		log.Fatalf("error in GetOuting: %v", err)
	}

	return &outing
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
		log.Fatalf("error in GetOutingAndGroupForOutingStep: %v", err)
	}

	// not possible to have 0 as ids: means that we didn't find the rows
	if res.OutingID == 0 && res.GroupID == 0 {
		return OutingAndGroupID{}, fmt.Errorf("outing step not found")
	}

	return res, nil
}

func (db *Database) GetAllOutings(groupId uint) []Outing {
	var outings []Outing

	// preloading is not efficient
	err := db.conn.Model(&Outing{}).
		Where("group_id = ?", groupId).
		Preload("Steps").
		Preload("Steps.Votes").
		Find(&outings).
		Error

	if err != nil {
		log.Fatalf("error in GetAllOutings: %v", err)
	}

	return outings
}

func (db *Database) GetActiveOuting(groupId uint) *Outing {
	var outing Outing
	err := db.conn.Model(&Outing{}).
		Where("id = (select active_outing_id from groups where id = ?)", groupId).
		Preload("Steps").
		Preload("Steps.Votes").
		First(&outing).
		Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil
		}
		log.Fatalf("error in GetActiveOuting: %v", err)
	}
	return &outing
}

func (db *Database) UpdateActiveOuting(groupId uint, outingId uint) error {
	err := db.conn.Model(&Group{}).
		Where("id = ?", groupId).
		Update("active_outing_id", outingId).
		Error
	return err
}

func (db *Database) CreateGroupInvite(inv *GroupInvite) error {
	return db.conn.Create(inv).Error
}

func (db *Database) GetGroupInvites(groupId uint) []GroupInvite {
	var invites []GroupInvite

	err := db.conn.Model(&GroupInvite{GroupID: groupId, Active: true}).
		Where("expiry IS NULL OR expiry > now()").
		Find(&invites).Error

	if err != nil {
		log.Fatalf("error in GetGroupInvites: %v", err)
		return nil
	}

	return invites
}

func (db *Database) InvalidateInvite(userId uint, inviteId uuid.UUID) error {
	return db.conn.Exec(`UPDATE group_invites SET active = FALSE WHERE id = ? AND 
		group_id IN (SELECT group_id FROM group_members WHERE user_id = ?)`, inviteId, userId).Error
}

func (db *Database) JoinByInvite(userId uint, inviteId uuid.UUID) error {
	var invite GroupInvite
	err := db.conn.Model(&GroupInvite{ID: inviteId, Active: true}).
		Where("expiry IS NULL OR expiry > now()").
		First(&invite).Error

	if err != nil {
		log.Fatalf("error in JoinByInvite: %v", err)
		return nil
	}

	_, err = db.AddUserToGroup(userId, invite.GroupID)
	return err
}
