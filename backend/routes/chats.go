package routes

import (
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
	"time"
)

type ChatController struct {
	Database *data.Database
	Auth     *services.AuthService
}

type SendMessageDto struct {
	Content string `json:"content" binding:"required"`
	GroupID uint   `json:"groupId" binding:"required"`
}

type GetMessagesDto struct {
	Start   time.Time `query:"start" binding:"required" format:"date-time"`
	End     time.Time `query:"end" binding:"required,gtfield=Start" format:"date-time"`
	GroupID uint      `query:"groupId" binding:"required"`
}

type MessageDto struct {
	SentAt  time.Time      `json:"sentAt" binding:"required" format:"date-time"`
	Content string         `json:"content" binding:"required"`
	User    UserSummaryDto `json:"user" binding:"required"`
}

// Send godoc
// @Summary Send a message
// @Description Send a new message to a `Group`
// @Param body body SendMessageDto true "Chat message"
// @Tags Chat
// @Security JWT
// @Success 200
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/chats/send [post]
func (controller ChatController) Send(ctx *gin.Context) {
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

	err := controller.Database.CreateMessage(data.Message{
		Content: sendMessageDto.Content,
		ByID:    groupMember.ID,
		SentAt:  time.Now(),
	})

	if err != nil {
		log.Print(err)
		ctx.Status(http.StatusBadRequest)
		return
	}

	ctx.Status(http.StatusOK)
}

// Get godoc
// @Summary Get messages
// @Description Get messages bound by a time range
// @Param query query GetMessagesDto true "body"
// @Tags Chat
// @Security JWT
// @Success 200 {object} []MessageDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/chats/all [get]
func (controller ChatController) Get(ctx *gin.Context) {
	userId := controller.Auth.AuthenticatedUserId(ctx)

	var getMessagesDto GetMessagesDto
	if err := ctx.BindQuery(&getMessagesDto); err != nil {
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
				Nickname: msg.By.User.Nickname,
			},
		}
	}
	ctx.JSON(http.StatusOK, dtos)
}

// Register the routes for this controller
func (controller ChatController) Register(router *gin.RouterGroup) {
	group := router.Group("chats")
	group.POST("send", controller.Send)
	group.GET("all", controller.Get)
}
