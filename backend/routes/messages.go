package routes

import (
	"github.com/gin-gonic/gin"
	socketio "github.com/googollee/go-socket.io"
	"github.com/googollee/go-socket.io/engineio"
	"log"
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

type GetMessagesDto struct {
	Start   time.Time `form:"start" json:"start" binding:"required" format:"date-time"`
	End     time.Time `form:"end" json:"end" binding:"required,gtfield=Start" format:"date-time"`
	GroupID uint      `form:"groupId" json:"groupId" binding:"required"`
}

type MessageDto struct {
	SentAt  time.Time      `json:"sentAt" binding:"required" format:"date-time"`
	Content string         `json:"content" binding:"required"`
	User    UserSummaryDto `json:"user" binding:"required"`
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
func (controller *MessageController) Send(ctx *gin.Context) {
	userId := controller.Auth.AuthenticatedUserId(ctx)

	var sendMessageDto SendMessageDto

	if err := Body(ctx, &sendMessageDto); err != nil {
		return
	}

	groupMember := controller.Database.GetGroupMember(userId, sendMessageDto.GroupID)

	if groupMember == nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("user is not a member of this group"))
		return
	}

	msg := data.Message{
		Content: sendMessageDto.Content,
		ByID:    groupMember.ID,
		SentAt:  time.Now(),
	}

	err := controller.Database.CreateMessage(&msg)

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	user := controller.Database.GetUser(userId)

	controller.WsServer.BroadcastToRoom("/", strconv.Itoa(int(sendMessageDto.GroupID)), "message", MessageDto{
		SentAt:  msg.SentAt,
		Content: msg.Content,
		User: UserSummaryDto{
			Name:     user.Name,
			Nickname: user.Username,
		},
	})

	ctx.Status(http.StatusOK)
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
func (controller *MessageController) Get(ctx *gin.Context) {
	userId := controller.Auth.AuthenticatedUserId(ctx)

	var getMessagesDto GetMessagesDto
	if err := Query(ctx, &getMessagesDto); err != nil {
		return
	}

	if controller.Database.GetGroupMember(userId, getMessagesDto.GroupID) == nil {
		ctx.JSON(http.StatusBadRequest, NewErrorMessage("user is not a member of this group"))
		return
	}

	messages := controller.Database.GetMessages(getMessagesDto.GroupID, getMessagesDto.Start, getMessagesDto.End)

	dtos := make([]MessageDto, len(messages))
	for i, msg := range messages {
		dtos[i] = MessageDto{
			SentAt:  msg.SentAt,
			Content: msg.Content,
			User: UserSummaryDto{
				Name:     msg.By.User.Name,
				Nickname: msg.By.User.Username,
			},
		}
	}
	ctx.JSON(http.StatusOK, dtos)
}

func (controller *MessageController) OnSocketError(conn socketio.Conn, err error) {
	log.Printf("[WARN] websocket error: %v", err) // warning only
}

func (controller *MessageController) OnSocketConnect(conn socketio.Conn) error {
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
func (controller *MessageController) Register(router *gin.RouterGroup) {
	controller.WsServer = socketio.NewServer(&engineio.Options{})
	if controller.WsServer == nil {
		log.Fatalf("message websocket creation error")
	}
	controller.WsServer.OnConnect("/", controller.OnSocketConnect)
	controller.WsServer.OnError("/", controller.OnSocketError)

	group := router.Group("messages")
	group.POST("send", controller.Send)
	group.GET("all", controller.Get)

	group.Any("socket/*any", func(c *gin.Context) {

		var groupId int
		var err error
		userId := controller.Auth.AuthenticatedUserId(c)

		if groupId, err = strconv.Atoi(c.Query("groupId")); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid groupId"})
			return
		}

		groupMember := controller.Database.GetGroupMember(userId, uint(groupId))

		if groupMember == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user is not a member of this group"})
			return
		}

		// Seriously, engineio.Conn can't be directly modified.
		// It's sent into ConnInitor function of WsServer by-value so
		// we can't even modify the context. Instead, I have to rely on silly
		// tricks like below.
		c.Request.Header.Set("User-Id", strconv.Itoa(int(userId)))
		c.Request.Header.Set("Group-Id", strconv.Itoa(groupId))
		c.Request.Header.Set("Group-Member-Id", strconv.Itoa(int(groupMember.ID)))

		controller.WsServer.ServeHTTP(c.Writer, c.Request)
	})
}
