package data

import (
	"time"
)

type User struct {
	ID             uint   `gorm:"primarykey"`
	Nickname       string `gorm:"unique"` // Tag of a user e.g. @chocoloco
	Name           string // Real-life (hopefully) name
	FirebaseUid    string `gorm:"unique"`
	GroupMembersAs []GroupMember
}

type Group struct {
	ID           uint `gorm:"primarykey"`
	Name         string
	Description  string
	OwnerID      uint
	Owner        *GroupMember `gorm:"foreignKey:OwnerID"`
	GroupMembers []GroupMember
	Outings      []Outing
}

type GroupMember struct {
	ID                uint `gorm:"primarykey"`
	UserID            uint
	User              *User `gorm:"foreignKey:UserID"`
	GroupID           uint
	Group             *Group `gorm:"foreignKey:GroupID"`
	LastSeenMessageID uint
	LastSeenMessage   *Message `gorm:"foreignKey:LastSeenMessageID"`
}

type Message struct {
	ID      uint `gorm:"primarykey"`
	Content string
	SentAt  time.Time
	ByID    uint
	By      *GroupMember `gorm:"foreignKey:ByID"`
}

type Outing struct {
	ID          uint `gorm:"primarykey"`
	GroupID     uint
	Group       *Group `gorm:"foreignKey:GroupID"`
	Name        string
	Description string
}

type OutingStep struct {
	ID           uint `gorm:"primarykey"`
	OutingID     uint
	Outing       *Outing `gorm:"foreignKey:OutingID"`
	Name         string
	Description  string
	WhereName    string
	WherePoint   string // TODO find a better type, supposed to be `point`
	When         time.Time
	Votes        []OutingStepVote
	VoteDeadline time.Time
}

type OutingStepVote struct {
	GroupMemberID uint
	GroupMember   *GroupMember `gorm:"foreignKey:GroupMemberID"`
	OutingStepID  uint
	OutingStep    *OutingStep `gorm:"foreignKey:OutingStepID"`
	Vote          bool
	VotedAt       time.Time
}
