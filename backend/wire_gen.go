// Code generated by Wire. DO NOT EDIT.

//go:generate go run github.com/google/wire/cmd/wire
//go:build !wireinject
// +build !wireinject

package main

import (
	"github.com/gin-gonic/gin"
	"github.com/google/wire"
	"planlah.sg/backend/data"
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
)

import (
	_ "planlah.sg/backend/docs"
)

// Injectors from deps.go:

func InitializeServer() (*gin.Engine, error) {
	db, err := data.NewDatabaseConnection()
	if err != nil {
		return nil, err
	}
	database := data.NewDatabase(db)
	authService, err := services.NewAuthService(database)
	if err != nil {
		return nil, err
	}
	userController := routes.UserController{
		Database: database,
		Auth:     authService,
	}
	groupsController := routes.GroupsController{
		Database: database,
		Auth:     authService,
	}
	miscController := routes.MiscController{}
	engine, err := NewServer(userController, groupsController, miscController, authService)
	if err != nil {
		return nil, err
	}
	return engine, nil
}

// deps.go:

var depSet = wire.NewSet(services.NewAuthService, data.NewDatabaseConnection, data.NewDatabase, wire.Struct(new(routes.UserController), "*"), wire.Struct(new(routes.GroupsController), "*"), wire.Struct(new(routes.MiscController), "*"), NewServer)
