package routes

import (
	"github.com/gin-gonic/gin"
	socketio "github.com/googollee/go-socket.io"
	"github.com/googollee/go-socket.io/engineio"
	"github.com/juju/errors"
	"github.com/samber/lo"
	"go.uber.org/zap"
	"net/http"
	"planlah.sg/backend/data"
	"strconv"
	"time"
)

type MessageController struct {
	BaseController
	WsServer *socketio.Server `wire:"-"` // we will be initializing this ourselves
}

type SendMessageDto struct {
	Content string `json:"content" binding:"required"`
	GroupID uint   `json:"groupId" binding:"required"`
}

type MarkReadDto struct {
	MessageID uint `json:"messageId" binding:"required"`
}

type GetRelativeMessagesDto struct {
	MessageID uint `form:"messageId" json:"messageId" binding:"required"`
	Count     uint `form:"count" json:"count" binding:"required"`
}

type GetMessagesDto struct {
	Start   time.Time `form:"start" json:"start" binding:"required" format:"date-time"`
	End     time.Time `form:"end" json:"end" binding:"required,gtfield=Start" format:"date-time"`
	GroupID uint      `form:"groupId" json:"groupId" binding:"required"`
}

type MessageDto struct {
	ID      uint           `json:"id" binding:"required"`
	SentAt  time.Time      `json:"sentAt" binding:"required" format:"date-time"`
	Content string         `json:"content" binding:"required"`
	User    UserSummaryDto `json:"user" binding:"required"`
}

func ToMessageDto(msg data.Message) MessageDto {
	return MessageDto{
		ID:      msg.ID,
		SentAt:  msg.SentAt,
		Content: msg.Content,
		User:    ToUserSummaryDto(*msg.By.User),
	}
}

func ToMessageDtos(messages []data.Message) []MessageDto {
	return lo.Map(messages, func(msg data.Message, _ int) MessageDto {
		return ToMessageDto(msg)
	})
}

// Send godoc
// @Summary Send a message
// @Description Send a new message to a `Group`
// @Param body body SendMessageDto true "Message"
// @Tags Message
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/messages/send [post]
func (ctr *MessageController) Send(ctx *gin.Context) {
	var dto SendMessageDto

	if Body(ctx, &dto) {
		return
	}

	groupMember := ctr.AuthGroupMember(ctx, dto.GroupID)
	if groupMember == nil {
		return
	}

	msg := data.Message{
		Content: dto.Content,
		ByID:    groupMember.ID,
		SentAt:  time.Now().In(time.UTC),
	}

	err := ctr.Database.CreateMessage(&msg)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	user, err := ctr.Database.GetUser(groupMember.UserID)
	if err != nil { // the user is always found
		handleDbError(ctx, err)
		return
	}

	ctr.WsServer.BroadcastToRoom("/", strconv.Itoa(int(dto.GroupID)), "message", MessageDto{
		ID:      msg.ID,
		SentAt:  msg.SentAt,
		Content: msg.Content,
		User:    ToUserSummaryDto(user),
	})

	ctx.Status(http.StatusOK)
}

// MarkRead godoc
// @Summary Mark a message as read
// @Description Marks a message as read and sets the last seen message of the user to this message if it's newer
// @Param body body MarkReadDto true "MarkRead"
// @Tags Message
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/messages/mark_read [put]
func (ctr *MessageController) MarkRead(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto MarkReadDto
	if Body(ctx, &dto) {
		return
	}

	err := ctr.Database.SetLastSeenMessageIDIfNewer(userId, dto.MessageID)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.Status(http.StatusOK)
}

// MessagesBefore godoc
// @Summary Get messages before this message
// @Description Get {count} number of messages before the message specified by the {messageId}
// @Param query query GetRelativeMessagesDto true "body"
// @Tags Message
// @Security JWT
// @Success 200 {object} []MessageDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/messages/before [get]
func (ctr *MessageController) MessagesBefore(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto GetRelativeMessagesDto
	if Query(ctx, &dto) {
		return
	}

	messages, err := ctr.Database.GetMessagesRelative(userId, dto.MessageID, dto.Count, true)
	if err != nil {
		if errors.Is(err, data.EntityNotFound) {
			FailWithMessage(ctx, "message is not in any of user's groups")
			return
		}
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToMessageDtos(messages))
}

// MessagesAfter godoc
// @Summary Get messages after this message
// @Description Get {count} number of messages after the message specified by the {messageId}
// @Param query query GetRelativeMessagesDto true "body"
// @Tags Message
// @Security JWT
// @Success 200 {object} []MessageDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/messages/after [get]
func (ctr *MessageController) MessagesAfter(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto GetRelativeMessagesDto
	if Query(ctx, &dto) {
		return
	}

	messages, err := ctr.Database.GetMessagesRelative(userId, dto.MessageID, dto.Count, false)
	if err != nil {
		if errors.Is(err, data.EntityNotFound) {
			FailWithMessage(ctx, "message is not in any of user's groups")
			return
		}
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToMessageDtos(messages))
}

// Get godoc
// @Summary Get messages
// @Description Get messages bound by a time range
// @Param query query GetMessagesDto true "body"
// @Tags Message
// @Security JWT
// @Success 200 {object} []MessageDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/messages/all [get]
func (ctr *MessageController) Get(ctx *gin.Context) {
	var dto GetMessagesDto
	if Query(ctx, &dto) {
		return
	}

	if ctr.AuthGroupMember(ctx, dto.GroupID) == nil {
		return
	}

	messages, err := ctr.Database.GetMessages(dto.GroupID, dto.Start, dto.End)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToMessageDtos(messages))
}

func (ctr *MessageController) OnSocketError(conn socketio.Conn, err error) {
	ctr.Logger.Warn("websocket", zap.Error(err))
}

func (ctr *MessageController) OnSocketConnect(conn socketio.Conn) error {
	header := conn.RemoteHeader()

	// there will not be an error as we are the ones setting it
	userId, _ := strconv.Atoi(header.Get("User-Id"))
	groupId, _ := strconv.Atoi(header.Get("Group-Id"))
	groupMemberId, _ := strconv.Atoi(header.Get("Group-Member-Id"))
	conn.SetContext(data.GroupMember{
		ID:      uint(groupMemberId),
		UserID:  uint(userId),
		GroupID: uint(groupId),
	})
	conn.Join(strconv.Itoa(groupId))
	return nil
}

// Register the routes for this controller
func (ctr *MessageController) Register(router *gin.RouterGroup) {
	ctr.WsServer = socketio.NewServer(&engineio.Options{})
	if ctr.WsServer == nil {
		ctr.Logger.Fatal("websocket init")
	}
	ctr.WsServer.OnConnect("/", ctr.OnSocketConnect)
	ctr.WsServer.OnError("/", ctr.OnSocketError)

	group := router.Group("messages")
	group.POST("send", ctr.Send)
	group.GET("all", ctr.Get)
	group.GET("before", ctr.MessagesBefore)
	group.GET("after", ctr.MessagesAfter)
	group.PUT("mark_read", ctr.MarkRead)

	group.Any("socket/*any", func(c *gin.Context) {

		var groupId int
		var err error
		userId := ctr.Auth.AuthenticatedUserId(c)

		if groupId, err = strconv.Atoi(c.Query("groupId")); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid groupId"})
			return
		}

		groupMember, err := ctr.Database.GetGroupMember(userId, uint(groupId))

		if groupMember == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user is not a member of this group"})
			return
		}
		if err != nil {
			handleDbError(c, err)
			return
		}

		// Seriously, engineio.Conn can't be directly modified.
		// It's sent into ConnInitor function of WsServer by-value so
		// we can't even modify the context. Instead, I have to rely on silly
		// tricks like below.
		c.Request.Header.Set("User-Id", strconv.Itoa(int(userId)))
		c.Request.Header.Set("Group-Id", strconv.Itoa(groupId))
		c.Request.Header.Set("Group-Member-Id", strconv.Itoa(int(groupMember.ID)))

		ctr.WsServer.ServeHTTP(c.Writer, c.Request)
	})
}
