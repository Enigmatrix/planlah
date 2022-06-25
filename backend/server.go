package main

import (
	"errors"
	"fmt"
	jwt "github.com/appleboy/gin-jwt/v2"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"log"
	"math/rand"
	"planlah.sg/backend/data"
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
)

// NewServer creates a new server and sets up middleware
func NewServer(
	users routes.UserController,
	groups routes.GroupsController,
	devPanel routes.DevPanelController,
	messages routes.MessageController,
	outings routes.OutingController,
	misc routes.MiscController,
	authSvc *services.AuthService) (*gin.Engine, error) {
	srv := gin.Default()

	var secret [256]byte
	_, err := rand.Read(secret[:])
	if err != nil {
		return nil, errors.New(fmt.Sprintf("failed to get random bytes for secret: %v", err))
	}

	// https://github.com/appleboy/gin-jwt
	identityKey := authSvc.IdentityKey
	authMiddleware, err := jwt.New(&jwt.GinJWTMiddleware{
		Realm:       "planlah_realm",
		Key:         secret[:],
		IdentityKey: identityKey,
		// Authenticates the Firebase Token, finds the corresponding User for this token
		Authenticator: authSvc.Verify,
		// Transform the User into data that can be encoded (in plaintext) in each JWT Token
		PayloadFunc: func(payload interface{}) jwt.MapClaims {
			if user, ok := payload.(*data.User); ok {
				return jwt.MapClaims{
					identityKey: user.ID,
				}
			}
			return jwt.MapClaims{}
		},
	})

	if err != nil {
		return nil, errors.New(fmt.Sprintf("create JWT middleware: %v", err))
	}

	err = authMiddleware.MiddlewareInit()

	if err != nil {
		return nil, errors.New(fmt.Sprintf("initialize JWT middleware: %v", err))
	}

	authMiddlewareFunc := authMiddleware.MiddlewareFunc()

	unauthapi := srv.Group("api")
	misc.Register(unauthapi)

	api := srv.Group("api")
	// protect all routes using JWT middleware
	api.Use(authMiddlewareFunc)
	users.Register(api)
	groups.Register(api)
	devPanel.Register(api)
	messages.Register(api)
	outings.Register(api)

	// serve websocket in goroutine.
	go func() {
		if err := messages.WsServer.Serve(); err != nil {
			log.Fatalf("message websocket listen error: %v", err)
		}
	}()

	// the websocket gets cleaned anyway, so don't bother closing it

	//defer func() {
	//	if err := messages.WsServer.Close(); err != nil {
	//		log.Fatalf("message websocket close error: %v", err)
	//	}
	//}()

	// unauthenticated routes
	srv.POST("/api/users/create", users.Create)
	srv.POST("/api/auth/verify", authMiddleware.LoginHandler)
	// Swagger documentation
	srv.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	return srv, nil
}
