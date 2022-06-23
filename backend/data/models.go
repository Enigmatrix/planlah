package data

import (
	"github.com/lib/pq"
	"time"
)

type User struct {
	ID             uint            `gorm:"primarykey"`
	Username       string          `gorm:"unique;not null"` // Tag of a user e.g. @chocoloco
	Name           string          `gorm:"not null"`        // Real-life (hopefully) name
	Gender         string          `gorm:"not null"`
	Town           string          `gorm:"not null"`
	FirebaseUid    string          `gorm:"unique;not null"`
	Attractions    pq.Float64Array `gorm:"type:float8[]"`
	Food           pq.Float64Array `gorm:"type:float8[]"`
	GroupMembersAs []GroupMember
}

type Group struct {
	ID           uint         `gorm:"primarykey"`
	Name         string       `gorm:"not null"`
	Description  string       `gorm:"not null"`
	OwnerID      uint         // this will be null when the Group is created, then updated instantly
	Owner        *GroupMember `gorm:"foreignKey:OwnerID"`
	GroupMembers []GroupMember
	Outings      []Outing
}

// GroupMember TODO: (UserID, GroupID) should be made unique
type GroupMember struct {
	ID                uint     `gorm:"primarykey"`
	UserID            uint     `gorm:"not null; uniqueIndex:composite_grp_member_idx"`
	User              *User    `gorm:"foreignKey:UserID"`
	GroupID           uint     `gorm:"not null; uniqueIndex:composite_grp_member_idx"`
	Group             *Group   `gorm:"foreignKey:GroupID"`
	LastSeenMessageID uint     // this will be nullable when the GroupMember just joins
	LastSeenMessage   *Message `gorm:"foreignKey:LastSeenMessageID"`
}

type Message struct {
	ID      uint         `gorm:"primarykey"`
	Content string       `gorm:"not null"`
	SentAt  time.Time    `gorm:"not null"`
	ByID    uint         `gorm:"not null"`
	By      *GroupMember `gorm:"foreignKey:ByID"`
}

type Outing struct {
	ID          uint   `gorm:"primarykey"`
	GroupID     uint   `gorm:"not null"`
	Group       *Group `gorm:"foreignKey:GroupID"`
	Name        string `gorm:"not null"`
	Description string `gorm:"not null"`
}

type OutingStep struct {
	ID           uint      `gorm:"primarykey"`
	OutingID     uint      `gorm:"not null"`
	Outing       *Outing   `gorm:"foreignKey:OutingID"`
	Name         string    `gorm:"not null"`
	Description  string    `gorm:"not null"`
	WhereName    string    `gorm:"not null"`
	WherePoint   string    `gorm:"not null"` // TODO find a better type, supposed to be `point`
	When         time.Time `gorm:"not null"`
	Votes        []OutingStepVote
	VoteDeadline time.Time `gorm:"not null"`
}

type OutingStepVote struct {
	GroupMemberID uint         `gorm:"primaryKey;autoIncrement:false"`
	GroupMember   *GroupMember `gorm:"foreignKey:GroupMemberID"`
	OutingStepID  uint         `gorm:"primaryKey;autoIncrement:false"`
	OutingStep    *OutingStep  `gorm:"foreignKey:OutingStepID"`
	Vote          bool         `gorm:"not null"`
	VotedAt       time.Time    `gorm:"not null"`
}
