package main

import (
	"log"

	"github.com/joho/godotenv"
	"go.uber.org/zap"
	_ "planlah.sg/backend/docs" // to get generated swagger docs to be enabled
	"planlah.sg/backend/utils"
)

//@title Planlah Backend API
//@version 1.0
//@description This is the API for planlah's backend API

// @securityDefinitions.apiKey JWT
// @in header
// @name Authorization
// @description Type 'Bearer TOKEN' to correctly set the API Key

func NewLogger(config *utils.Config) *zap.Logger {
	var logger *zap.Logger
	var err error
	if config.AppMode == utils.Dev || config.AppMode == utils.Orbital {
		logger, err = zap.NewDevelopment()
		logger.Sugar()
	} else {
		logger, err = zap.NewProduction()
	}

	if err != nil {
		// who logs the loggers?
		log.Fatalf("can't initialize zap logger: %v", err)
	}

	return logger
}

func main() {
	err := godotenv.Load("./.env")
	if err != nil {
		log.Printf("[WARN] loading base .env file: %v", err)
	}

	err = godotenv.Load("../.env")
	if err != nil {
		log.Fatalf("loading .env file: %v", err)
		return
	}

	logger, err := GetLogger()
	if err != nil {
		log.Fatalf("creating logger: %v", err)
		return
	}

	srv, err := InitializeServer()
	if err != nil {
		logger.Sugar().Fatal("initialize server", "err", err)
		return
	}

	err = srv.Run()
	if err != nil {
		logger.Sugar().Fatal("running server", "err", err)
		return
	}
}
