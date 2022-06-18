package data

import (
	"errors"
	"fmt"
	"github.com/jackc/pgconn"
	"github.com/jackc/pgerrcode"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"os"
	"planlah.sg/backend/utils"
	"time"
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

func (db *Database) CreateGroup(group *Group) error {
	return db.conn.Omit("OwnerID").Create(group).Error
}

func (db *Database) CreateGroupMember(groupMember *GroupMember) error {
	return db.conn.Omit("LastSeenMessageID").Create(groupMember).Error
}

func (db *Database) UpdateGroupOwner(groupID uint, ownerID uint) error {
	return db.conn.Model(&Group{ID: groupID}).Update("OwnerID", ownerID).Error
}
