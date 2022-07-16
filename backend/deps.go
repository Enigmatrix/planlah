//go:build wireinject
// +build wireinject

package main

import (
	"github.com/gin-gonic/gin"
	"github.com/google/wire"
	"go.uber.org/zap"
	"planlah.sg/backend/data"
	"planlah.sg/backend/jobs"
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
	"planlah.sg/backend/utils"
)

var depSet = wire.NewSet(
	// util
	utils.NewConfig,
	NewLogger,

	// services
	services.NewFirebaseApp,
	services.NewAuthService,
	// wire.Bind(new(services.ImageService), new(*services.FirebaseStorageImageService)),
	// services.NewFirebaseStorageImageService,
	// use ImageKit instead of sad firebase
	services.NewImageKitImageService,
	wire.Bind(new(services.ImageService), new(*services.ImageKitImageService)),

	// jobs
	jobs.NewVoteDeadlineJob,
	jobs.NewJobsRunner,

	// database
	data.NewDatabaseConnection,
	data.NewDatabase,

	// server
	wire.Struct(new(routes.BaseController), "*"),
	wire.Struct(new(routes.UserController), "*"),
	wire.Struct(new(routes.GroupsController), "*"),
	wire.Struct(new(routes.DevPanelController), "*"),
	wire.Struct(new(routes.MessageController), "*"),
	wire.Struct(new(routes.OutingController), "*"),
	wire.Struct(new(routes.MiscController), "*"),
	wire.Struct(new(routes.FriendsController), "*"),
	wire.Struct(new(routes.PlacesController), "*"),
	wire.Struct(new(routes.PostsController), "*"),
	wire.Struct(new(routes.ReviewsController), "*"),
	NewServer,
)

func InitializeServer() (*gin.Engine, error) {
	panic(wire.Build(depSet))
}

func GetLogger() (*zap.Logger, error) {
	panic(wire.Build(depSet))
}
