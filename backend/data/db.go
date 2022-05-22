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
		err = db.AutoMigrate(&User{})
		if err != nil {
			return nil, errors.New(fmt.Sprintf("error while migrating db: %v", err))
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

// FindUserByFirebaseUid gets a user given a unique firebaseUid
func (db *Database) FindUserByFirebaseUid(firebaseUid string) *User {
	var user User

	err := db.conn.Where(&User{FirebaseUid: firebaseUid}).
		Select("ID").First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}

	return &user
}
