//go:build wireinject
// +build wireinject

package main

import (
	"github.com/gin-gonic/gin"
	"github.com/google/wire"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
)

func NewServer(user routes.UserController, auth routes.AuthController) (*gin.Engine, error) {
	srv := gin.Default()
	api := srv.Group("api")
	user.Register(api)
	auth.Register(api)
	// Swagger documentation
	srv.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
	return srv, nil
}

var depSet = wire.NewSet(
	services.NewAuthService,
	wire.Struct(new(routes.UserController), "*"),
	wire.Struct(new(routes.AuthController), "*"),
	NewServer,
)

func InitializeServer() (*gin.Engine, error) {
	panic(wire.Build(depSet))
}
