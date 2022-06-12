//go:build wireinject
// +build wireinject

package main

import (
	"github.com/gin-gonic/gin"
	"github.com/google/wire"
	"planlah.sg/backend/data"
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
)

var depSet = wire.NewSet(
	services.NewAuthService,
	data.NewDatabaseConnection,
	data.NewDatabase,
	wire.Struct(new(routes.UserController), "*"),
	wire.Struct(new(routes.GroupController), "*"),
	wire.Struct(new(routes.MessageController), "*"),
	wire.Struct(new(routes.DevPanelController), "*"),
	wire.Struct(new(routes.OutingController), "*"),
	wire.Struct(new(routes.MiscController), "*"),
	NewServer,
)

func InitializeServer() (*gin.Engine, error) {
	panic(wire.Build(depSet))
}
