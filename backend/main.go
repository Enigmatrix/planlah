package main

import (
	"github.com/joho/godotenv"
	"log"
	_ "planlah.sg/backend/docs" // to get generated swagger docs to be enabled
)

//@title Planlah Backend API
//@version 1.0
//@description This is the API for planlah's backend API

// @securityDefinitions.apiKey JWT
// @in header
// @name Authorization
// @description Type 'Bearer TOKEN' to correctly set the API Key

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
		return
	}

	srv, err := InitializeServer()
	if err != nil {
		log.Fatalf("Cannot initialize server: %v", err)
		return
	}

	err = srv.Run()
	if err != nil {
		log.Fatalf("Error running server: %v", err)
		return
	}
}
