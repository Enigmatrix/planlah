package data

import (
	"github.com/google/uuid"
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
	ImageLink      string          `gorm:"not null"`
	Attractions    pq.Float64Array `gorm:"type:float8[]"`
	Food           pq.Float64Array `gorm:"type:float8[]"`
	GroupMembersAs []GroupMember
}

type FriendRequestStatus string

const (
	Approved FriendRequestStatus = "approved"
	Rejected FriendRequestStatus = "rejected"
	Pending  FriendRequestStatus = "pending"
)

type FriendRequest struct {
	FromID uint                `gorm:"primarykey"`
	From   *User               `gorm:"foreignKey:FromID"`
	ToID   uint                `gorm:"primarykey"`
	To     *User               `gorm:"foreignKey:ToID"`
	Status FriendRequestStatus `sql:"type:friend_request_status"`
}

type Group struct {
	ID             uint         `gorm:"primarykey"`
	Name           string       `gorm:"not null"`
	Description    string       `gorm:"not null"`
	ImageLink      string       `gorm:"not null"`
	OwnerID        uint         // this will be null when the Group is created, then updated instantly
	Owner          *GroupMember `gorm:"foreignKey:OwnerID"`
	ActiveOutingID uint         // this will be null when there is no active outing
	ActiveOuting   *Outing      `gorm:"foreignKey:ActiveOutingID"`
	GroupMembers   []GroupMember
	Outings        []Outing
}

type GroupInvite struct {
	ID      uuid.UUID `gorm:"type:uuid; primary_key; default:gen_random_uuid()"`
	Expiry  *time.Time
	Active  bool   `gorm:"not null"`
	GroupID uint   `gorm:"not null"`
	Group   *Group `gorm:"foreignKey:GroupID"`
}

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
	ID          uint      `gorm:"primarykey"`
	GroupID     uint      `gorm:"not null"`
	Group       *Group    `gorm:"foreignKey:GroupID"`
	Name        string    `gorm:"not null"`
	Description string    `gorm:"not null"`
	Start       time.Time `gorm:"not null"`
	End         time.Time `gorm:"not null"`
	Steps       []OutingStep
}

type OutingStep struct {
	ID           uint      `gorm:"primarykey"`
	OutingID     uint      `gorm:"not null"`
	Outing       *Outing   `gorm:"foreignKey:OutingID"`
	Name         string    `gorm:"not null"`
	Description  string    `gorm:"not null"`
	WhereName    string    `gorm:"not null"`
	WherePoint   string    `gorm:"not null"` // TODO find a better type, supposed to be `point`
	Start        time.Time `gorm:"not null"`
	End          time.Time `gorm:"not null"`
	VoteDeadline time.Time `gorm:"not null"`
	Votes        []OutingStepVote
}

type OutingStepVote struct {
	GroupMemberID uint         `gorm:"primaryKey;autoIncrement:false"`
	GroupMember   *GroupMember `gorm:"foreignKey:GroupMemberID"`
	OutingStepID  uint         `gorm:"primaryKey;autoIncrement:false"`
	OutingStep    *OutingStep  `gorm:"foreignKey:OutingStepID"`
	Vote          bool         `gorm:"not null"`
	VotedAt       time.Time    `gorm:"not null"`
}
