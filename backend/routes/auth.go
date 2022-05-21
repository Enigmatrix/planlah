package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"planlah.sg/backend/services"
)

type AuthController struct {
	AuthService *services.AuthService
}

type TokenDto struct {
	Token string `json:"token" binding:"required"`
}

// Verify
// @Summary Verify the Firebase Authentication Token
// @Description Verify the Firebase Authentication Token, and return our own App Authentication Token
// @Param body body TokenDto true "Firebase Authentication Token"
// @Success 200 {object} TokenDto
// @Failure 401 {object}  ErrorMessage
// @Router /api/auth/verify [post]
func (controller AuthController) Verify(ctx *gin.Context) {
	var dto TokenDto
	if err := Body(ctx, &dto); err != nil {
		return
	}
	firebaseToken := dto.Token

	uid, err := controller.AuthService.Verify(firebaseToken)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, ErrorMessage{Message: "invalid credentials"})
		return
	}

	ctx.JSON(http.StatusOK, TokenDto{Token: *uid})
}

// Register the routes for this controller
func (controller AuthController) Register(router *gin.RouterGroup) {
	group := router.Group("auth")
	group.POST("verify", controller.Verify)
}
