package users

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Ping users
// @Summary Ping
// @Description Ping testing method
// @Router /api/users/ping [get]
func Ping(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, gin.H{"message": "pong"})
}

func Register(router *gin.RouterGroup) {
	users := router.Group("users")
	{
		users.GET("ping", Ping)
	}
}
