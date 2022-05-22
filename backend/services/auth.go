package services

import (
	"context"
	"errors"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"fmt"
	"github.com/gin-gonic/gin"
	"planlah.sg/backend/data"
	lazy "planlah.sg/backend/utils"
	"time"
)

type AuthService struct {
	firebaseApp  *firebase.App
	firebaseAuth *auth.Client
	database     *data.Database
}

type TokenDtoRequest struct {
	Token string `json:"token" binding:"required"`
}

type TokenDtoResponse struct {
	Token  string    `json:"token" binding:"required"`
	Expire time.Time `json:"expire" binding:"required"`
	Code   int       `json:"code" binding:"required"`
}

type TokenDtoFailed struct {
	Message string `json:"message" binding:"required"`
	Code    int    `json:"code" binding:"required"`
}

var instance = lazy.New[AuthService]()

// NewAuthService creates a new AuthService
func NewAuthService(database *data.Database) (*AuthService, error) {
	return instance.FallibleValue(func() (*AuthService, error) {
		ctx := context.Background()
		firebaseApp, err := firebase.NewApp(ctx, nil)
		if err != nil {
			return nil, errors.New(fmt.Sprintf("cannot init firebase app: %v", err))
		}
		firebaseAuth, err := firebaseApp.Auth(context.Background())
		if err != nil {
			return nil, errors.New(fmt.Sprintf("cannot init firebase auth instance: %v", err))
		}
		return &AuthService{firebaseApp: firebaseApp, firebaseAuth: firebaseAuth, database: database}, nil
	})
}

// GetFirebaseUid uses the Firebase Token and returns the Authenticated User's UID
func (authSvc *AuthService) GetFirebaseUid(firebaseToken string) (*string, error) {
	verifiedToken, err := authSvc.firebaseAuth.VerifyIDToken(context.Background(), firebaseToken)
	if err != nil {
		return nil, errors.New("invalid firebase token")
	}
	return &verifiedToken.UID, nil
}

// GetUser uses the Firebase Token and retrieves the corresponding User
func (authSvc *AuthService) GetUser(firebaseToken string) (*data.User, error) {
	firebaseUid, err := authSvc.GetFirebaseUid(firebaseToken)
	if err != nil {
		return nil, err
	}

	user := authSvc.database.FindUserByFirebaseUid(*firebaseUid)
	if user == nil {
		return nil, errors.New("user not found")
	}
	return user, nil
}

// Verify
// @Summary Verify the Firebase Authentication Token
// @Description Verify the Firebase Authentication Token, and return our own App's JWT Token
// @Param body body TokenDtoRequest true "Firebase Authentication Token"
// @Success 200 {object} TokenDtoResponse
// @Failure 401 {object} TokenDtoFailed
// @Router /api/auth/verify [post]
func (authSvc *AuthService) Verify(ctx *gin.Context) (interface{}, error) {
	var dto TokenDtoRequest
	if err := ctx.ShouldBindJSON(&dto); err != nil {
		return nil, errors.New("invalid body")
	}
	user, err := authSvc.GetUser(dto.Token)
	if err != nil {
		return nil, err
	}
	return user, nil
}
