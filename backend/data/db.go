package data

import (
	"fmt"
	"github.com/juju/errors"
	"github.com/samber/lo"
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
	EntityNotFound     = errors.New("entity not found")
	UsernameExists     = errors.New("username taken")
	FirebaseUidExists  = errors.New("firebase uid taken")
	UserAlreadyInGroup = errors.New("user is already in group")
)

// NewDatabaseConnection Creates a new database connection
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

// GetUserByFirebaseUid Gets a User given a unique Firebase UID
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
	Group              Group
	UnreadMessageCount uint
	LastMessage        *Message
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

	groupInfos := lo.Map(groups, func(g Group, _ int) GroupInfo {
		var lastMsg *Message
		if msg, ok := lastMsgs[g.ID]; ok {
			lastMsg = &msg
		} else {
			lastMsg = nil
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
	err := db.conn.Where(&GroupMember{UserID: userId}).
		Joins("inner join groups g").
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
// even those the User is not joined into.
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

// UpdateGroupOwner Updates the Group owner.
//
// Does not check if the new owner is a GroupMember of this Group.
func (db *Database) UpdateGroupOwner(groupID uint, ownerID uint) error {
	return errors.Trace(db.conn.Model(&Group{ID: groupID}).Update("OwnerID", ownerID).Error)
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

// GetMessages Gets Messages within a time range
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
func (db *Database) CreateOutingStep(outingStep *OutingStep) error {
	return errors.Trace(db.conn.Create(outingStep).Error)
}

// UpsertOutingStepVote Vote for an OutingStep
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
	err := db.conn.Model(&Outing{ID: outingId}).
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
// Does not check if the User belongs to the Group
func (db *Database) GetAllOutings(groupId uint) ([]Outing, error) {
	var outings []Outing

	err := db.conn.Model(&Outing{}).
		Where("group_id = ?", groupId).
		Preload("Steps").
		Preload("Steps.Votes").
		Find(&outings).
		Error

	if err != nil {
		return nil, errors.Trace(err)
	}

	return outings, nil
}

// GetActiveOuting Gets the active Outing for a Group
//
// Does not check if the User belongs to the Group
func (db *Database) GetActiveOuting(groupId uint) (*Outing, error) {
	var outing Outing
	err := db.conn.Model(&Outing{}).
		Where("id = (select active_outing_id from groups where id = ?)", groupId).
		Preload("Steps").
		Preload("Steps.Votes").
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

	err := db.conn.Model(&GroupInvite{GroupID: groupId, Active: true}).
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
	err := db.conn.Table("group_invites gi").
		Where("gi.id = ? AND gi.active = TRUE", inviteId).
		Where("gi.expiry IS NULL OR gi.expiry > now()").
		First(&invite).Error

	if err != nil {
		return GroupInvite{}, errors.Trace(err)
	}

	_, err = db.AddUserToGroup(userId, invite.GroupID)
	return invite, errors.Trace(err)
}
