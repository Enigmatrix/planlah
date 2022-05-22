package data

import (
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"os"
	lazy "planlah.sg/backend/utils"
	"time"
)

var dbConn lazy.Lazy[gorm.DB]

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
			return nil, err
		}

		// add tables here
		err = db.AutoMigrate(&User{})
		if err != nil {
			return nil, err
		}

		sqlDB, err := db.DB()
		if err != nil {
			return nil, err
		}

		sqlDB.SetMaxOpenConns(16)
		sqlDB.SetConnMaxLifetime(time.Hour)
		return db, nil
	})
}

type Database struct {
	conn *gorm.DB
}

func NewDatabase(conn *gorm.DB) Database {
	return Database{conn: conn}
}

func (db *Database) CreateUser(user *User) {
	db.conn.Create(user)
}
