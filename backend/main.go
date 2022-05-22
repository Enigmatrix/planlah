package main

import (
	"github.com/joho/godotenv"
	"log"
	_ "planlah.sg/backend/docs" // to get generated swagger docs to be enabled
)

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
