package services

import (
	"context"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	jwt "github.com/appleboy/gin-jwt/v2"
	"github.com/gin-gonic/gin"
	"github.com/juju/errors"
	"go.uber.org/zap"
	"planlah.sg/backend/data"
	lazy "planlah.sg/backend/utils"
	"time"
)

type AuthService struct {
	firebaseApp  *firebase.App
	firebaseAuth *auth.Client
	database     *data.Database
	logger       *zap.Logger
	IdentityKey  string
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

type AuthError struct {
	Message string `json:"message" binding:"required"`
	Code    int    `json:"code" binding:"required"`
}

var authServiceInstance = lazy.New[AuthService]()

// NewAuthService creates a new AuthService
func NewAuthService(database *data.Database, firebaseApp *firebase.App, logger *zap.Logger) (*AuthService, error) {
	return authServiceInstance.FallibleValue(func() (*AuthService, error) {
		firebaseAuth, err := firebaseApp.Auth(context.Background())
		if err != nil {
			return nil, errors.Annotate(err, "cannot init firebase auth instance")
		}
		return &AuthService{firebaseApp: firebaseApp, firebaseAuth: firebaseAuth, database: database, logger: logger, IdentityKey: "id"}, nil
	})
}

// GetFirebaseUid uses the Firebase Token and returns the Authenticated User's UID
func (authSvc *AuthService) GetFirebaseUid(firebaseToken string) (*string, error) {
	verifiedToken, err := authSvc.firebaseAuth.VerifyIDToken(context.Background(), firebaseToken)
	if err != nil {
		return nil, errors.Annotate(err, "invalid firebase token")
	}
	return &verifiedToken.UID, nil
}

// GetUser uses the Firebase Token and retrieves the corresponding User
func (authSvc *AuthService) GetUser(firebaseToken string) (data.User, error) {
	firebaseUid, err := authSvc.GetFirebaseUid(firebaseToken)
	if err != nil {
		return data.User{}, errors.Trace(err)
	}
	user, err := authSvc.database.GetUserByFirebaseUid(*firebaseUid)
	return user, errors.Trace(err)
}

// Verify godoc
// @Summary Verify the Firebase Authentication Token
// @Description Verify the Firebase Authentication Token, and return our own App's JWT Token
// @Param body body TokenDtoRequest true "Firebase Authentication Token"
// @Tags Authentication
// @Success 200 {object} TokenDtoResponse
// @Failure 401 {object} TokenDtoFailed
// @Router /api/auth/verify [post]
func (authSvc *AuthService) Verify(ctx *gin.Context) (interface{}, error) {
	var dto TokenDtoRequest
	if err := ctx.BindJSON(&dto); err != nil {
		return nil, errors.Annotate(err, "token dto parsing")
	}
	user, err := authSvc.GetUser(dto.Token)

	if errors.Is(err, data.EntityNotFound) {
		return nil, errors.New("user does not exist")
	} else if err != nil {
		// TODO handle the error here!
		return nil, err
	}

	return user, err
}

func (authSvc *AuthService) AuthenticatedUserId(ctx *gin.Context) uint {
	claims := jwt.ExtractClaims(ctx)
	userId := claims[authSvc.IdentityKey]

	if v, ok := userId.(float64); ok {
		return uint(v)
	}

	authSvc.logger.Fatal("should not be called for unauthenticated routes")
	return 0 // doesnt reach here
}
