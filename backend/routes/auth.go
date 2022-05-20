package routes

import (
	"context"
	firebase "firebase.google.com/go/v4"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
)

type AuthController struct {
	FirebaseApp *firebase.App
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
	auth, err := controller.FirebaseApp.Auth(context.Background())
	if err != nil {
		log.Fatalf("Firebase Auth session failed to initialize: %v", err)
	}

	// TODO check possible errs?
	verifiedToken, err := auth.VerifyIDToken(context.Background(), firebaseToken)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, ErrorMessage{Message: "invalid credentials"})
		return
	}

	token := verifiedToken.UID

	ctx.JSON(http.StatusOK, TokenDto{Token: token})
}

// Register the routes for this controller
func (controller AuthController) Register(router *gin.RouterGroup) {
	group := router.Group("auth")
	group.POST("verify", controller.Verify)
}
