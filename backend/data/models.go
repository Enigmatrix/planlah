package data

import "gorm.io/gorm"

type User struct {
	gorm.Model
	Nickname    string `gorm:"unique"` // Tag of a user
	Name        string // Real-life (hopefully) name
	FirebaseUid string `gorm:"unique"`
}
