//go:build wireinject
// +build wireinject

package main

import (
	"github.com/gin-gonic/gin"
	"github.com/google/wire"
	"planlah.sg/backend/data"
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
	"planlah.sg/backend/utils"
)

var depSet = wire.NewSet(
	services.NewFirebaseApp,
	services.NewAuthService,

	// wire.Bind(new(services.ImageService), new(*services.FirebaseStorageImageService)),
	// services.NewFirebaseStorageImageService,
	// use ImageKit instead of sad firebase
	services.NewImageKitImageService,
	wire.Bind(new(services.ImageService), new(*services.ImageKitImageService)),

	data.NewDatabaseConnection,
	data.NewDatabase,
	wire.Struct(new(routes.BaseController), "*"),
	wire.Struct(new(routes.UserController), "*"),
	wire.Struct(new(routes.GroupsController), "*"),
	wire.Struct(new(routes.DevPanelController), "*"),
	wire.Struct(new(routes.MessageController), "*"),
	wire.Struct(new(routes.MiscController), "*"),
	wire.Struct(new(routes.OutingController), "*"),
	NewServer,
	utils.NewConfig,
)

func InitializeServer() (*gin.Engine, error) {
	panic(wire.Build(depSet))
}
