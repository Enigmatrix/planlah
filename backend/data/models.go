package data

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/juju/errors"
	"github.com/lib/pq"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
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

type PlaceType string

const (
	Attraction PlaceType = "attraction"
	Restaurant PlaceType = "restaurant"
)

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
	IsDM           bool         `gorm:"not null"`
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
	ID           uint      `gorm:"primarykey"`
	GroupID      uint      `gorm:"not null"`
	Group        *Group    `gorm:"foreignKey:GroupID"`
	Name         string    `gorm:"not null"`
	Description  string    `gorm:"not null"`
	Start        time.Time `gorm:"not null"`
	End          time.Time `gorm:"not null"`
	VoteDeadline time.Time `gorm:"not null"`
	Steps        []OutingStep
}

type OutingStep struct {
	ID          uint             `gorm:"primarykey"`
	OutingID    uint             `gorm:"not null"`
	Outing      *Outing          `gorm:"foreignKey:OutingID"`
	PlaceID     uint             `gorm:"not null"`
	Place       *Place           `gorm:"foreignKey:PlaceID"`
	Description string           `gorm:"not null"`
	Start       time.Time        `gorm:"not null"`
	End         time.Time        `gorm:"not null"`
	Votes       []OutingStepVote `gorm:"constraint:OnDelete:CASCADE;"`
}

type OutingStepVote struct {
	GroupMemberID uint         `gorm:"primaryKey;autoIncrement:false"`
	GroupMember   *GroupMember `gorm:"foreignKey:GroupMemberID"`
	OutingStepID  uint         `gorm:"primaryKey;autoIncrement:false"`
	OutingStep    *OutingStep  `gorm:"foreignKey:OutingStepID"`
	Vote          bool         `gorm:"not null"`
	VotedAt       time.Time    `gorm:"not null"`
}

type Place struct {
	ID               uint   `gorm:"primarykey"`
	Name             string `gorm:"not null; type:varchar(255)"`
	Location         string `gorm:"not null; type:varchar(255)"`
	Position         Point  `gorm:"not null"`
	FormattedAddress string `gorm:"not null; type:varchar(255)"`
	ImageUrl         string `gorm:"not null"`
	About            string
	PlaceType        PlaceType `gorm:"not null"`
	// Features will not be used by us
}

type Point struct {
	Longitude float64 `form:"longitude" uri:"longitude" json:"longitude" binding:"required"`
	Latitude  float64 `form:"latitude" uri:"latitude" json:"latitude" binding:"required"`
}

func (loc Point) GormDataType() string {
	return "geography"
}

func (loc Point) GormValue(ctx context.Context, db *gorm.DB) clause.Expr {
	return clause.Expr{
		SQL:  "ST_MakePoint(?, ?)",
		Vars: []interface{}{loc.Longitude, loc.Latitude},
	}
}

// Scan implements the sql.Scanner interface
func (loc *Point) Scan(v interface{}) error {
	pointText, ok := v.(string)
	if !ok {
		return errors.New("parse column as string")
	}
	n, err := fmt.Sscanf(pointText, "POINT(%f %f)", &loc.Longitude, &loc.Latitude)
	if err != nil {
		return errors.Annotate(err, "scanning in POINT format")
	}
	if n != 2 {
		return errors.New("not enough valid scans")
	}
	return nil
}
