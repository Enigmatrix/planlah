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
	services.NewFirebaseStorageImageService,
	wire.Bind(new(services.ImageService), new(*services.FirebaseStorageImageService)),
	data.NewDatabaseConnection,
	data.NewDatabase,
	wire.Struct(new(routes.BaseController), "*"),
	wire.Struct(new(routes.UserController), "*"),
	wire.Struct(new(routes.GroupsController), "*"),
	wire.Struct(new(routes.DevPanelController), "*"),
	wire.Struct(new(routes.MessageController), "*"),
	wire.Struct(new(routes.OutingController), "*"),
	wire.Struct(new(routes.MiscController), "*"),
	NewServer,
	utils.NewConfig,
)

func InitializeServer() (*gin.Engine, error) {
	panic(wire.Build(depSet))
}
