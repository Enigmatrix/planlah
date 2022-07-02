package main

import (
	jwt "github.com/appleboy/gin-jwt/v2"
	"github.com/gin-gonic/gin"
	errors2 "github.com/juju/errors"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"go.uber.org/zap"
	"math/rand"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
)

func authMiddleware(authSvc *services.AuthService) (*jwt.GinJWTMiddleware, gin.HandlerFunc, error) {
	var secret [256]byte
	_, err := rand.Read(secret[:])
	if err != nil {
		return nil, nil, errors2.Annotate(err, "failed to get random bytes for secret")
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
		return nil, nil, errors2.Annotate(err, "create JWT middleware")
	}

	err = authMiddleware.MiddlewareInit()

	if err != nil {
		return nil, nil, errors2.Annotate(err, "init JWT middleware")
	}

	authMiddlewareFunc := authMiddleware.MiddlewareFunc()

	return authMiddleware, authMiddlewareFunc, nil
}

func errorHandler(logger *zap.Logger) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		ctx.Next()

		for _, err := range ctx.Errors {
			logger.Sugar().Fatal("handler err", zap.String("handlerName", ctx.HandlerName()), zap.Error(err))
		}

		ctx.Status(http.StatusInternalServerError)
	}
}

// NewServer creates a new server and sets up middleware
func NewServer(
	users routes.UserController,
	groups routes.GroupsController,
	devPanel routes.DevPanelController,
	messages routes.MessageController,
	outings routes.OutingController,
	misc routes.MiscController,
	logger *zap.Logger,
	authSvc *services.AuthService) (*gin.Engine, error) {

	srv := gin.Default()

	authMiddleware, authProtect, err := authMiddleware(authSvc)
	if err != nil {
		return nil, errors2.Trace(err)
	}

	// use our custom error handlers
	srv.Use(errorHandler(logger))

	// no api prefix
	srv.GET("/join/:inviteId", groups.JoinByInviteUserLink)
	// unauthenticated routes
	{
		unauthApi := srv.Group("api")
		unauthApi.POST("users/create", users.Create)
		unauthApi.POST("auth/verify", authMiddleware.LoginHandler)
		misc.Register(unauthApi)
	}

	{
		// protect all routes using JWT middleware
		api := srv.Group("api")
		api.Use(authProtect)
		users.Register(api)
		groups.Register(api)
		devPanel.Register(api)
		messages.Register(api)
		outings.Register(api)
	}

	// serve websocket in goroutine.
	go func() {
		if err := messages.WsServer.Serve(); err != nil {
			logger.Sugar().Fatal("message websocket listen error", zap.Error(err))
		}
	}()

	// the websocket gets cleaned anyway, so don't bother closing it

	//defer func() {
	//	if err := messages.WsServer.Close(); err != nil {
	//		log.Fatalf("message websocket close error: %v", err)
	//	}
	//}()

	// Swagger documentation
	srv.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	return srv, nil
}
