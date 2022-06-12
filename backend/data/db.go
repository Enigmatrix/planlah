package data

import (
	"errors"
	"fmt"
	"github.com/jackc/pgconn"
	"github.com/jackc/pgerrcode"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"os"
	lazy "planlah.sg/backend/utils"
	"time"
)

var dbConn lazy.Lazy[gorm.DB]

// NewDatabaseConnection creates a new database connection
func NewDatabaseConnection() (*gorm.DB, error) {
	// TODO should this really be a singleton?
	return dbConn.FallibleValue(func() (*gorm.DB, error) {
		dsn := fmt.Sprintf("host=%s user=%s password=%s",
			os.Getenv("DB_HOST"),
			os.Getenv("DB_USER"),
			os.Getenv("DB_PASSWORD"),
		)
		pg := postgres.Open(dsn)
		config := gorm.Config{}

		db, err := gorm.Open(pg, &config)
		if err != nil {
			return nil, errors.New(fmt.Sprintf("cannot open db: %v", err))
		}

		// add tables here
		models := []interface{}{&User{}, &Group{}, &GroupMember{}, &Message{}, &Outing{}, &OutingStep{}, &OutingStepVote{}}

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

		sqlDB.SetMaxOpenConns(16)
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

func (db *Database) CreateGroup(group *Group) error {
	return db.conn.Omit("OwnerID").Create(group).Error
}

func (db *Database) CreateGroupMember(groupMember *GroupMember) error {
	return db.conn.Omit("LastSeenMessageID").Create(groupMember).Error
}

func (db *Database) GetGroupMember(userId uint, groupId uint) *GroupMember {
	var grpMember GroupMember
	err := db.conn.Model(&GroupMember{UserID: userId, GroupID: groupId}).First(&grpMember).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}
	return &grpMember
}

func (db *Database) UpdateGroupOwner(groupID uint, ownerID uint) error {
	return db.conn.Model(&Group{ID: groupID}).Update("OwnerID", ownerID).Error
}

func (db *Database) CreateMessage(msg *Message) error {
	return db.conn.Create(msg).Error
}

func (db *Database) GetMessages(groupId uint, start time.Time, end time.Time) []Message {
	var messages []Message

	// Use preload instead of join since the numbers of users/group_members loaded will be small
	// and the extra 2 sql statements executed will be cheap (ignoring latency)

	// This is an acceptable but lazy solution, of course, sourced from the horrible documentation of gorm.
	// However, once a better join solution (that loads the foreign table properties) exists, we should
	// use that
	err := db.conn.
		Preload("By", "group_id = ?", groupId).
		Preload("By.User").
		Find(&messages, "? > messages.sent_at and messages.sent_at >= ?", end, start).Error

	if err != nil {
		return nil
	}
	return messages
}

func (db *Database) CreateOuting(outing *Outing) interface{} {
	return db.conn.Create(outing).Error
}

func (db *Database) GetAllOutings(groupId uint) []Outing {
	// TODO
	return nil
}
