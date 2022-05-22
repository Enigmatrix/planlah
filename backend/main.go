package main

import (
	"github.com/joho/godotenv"
	"log"
	_ "planlah.sg/backend/docs" // to get generated swagger docs to be enabled
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	srv, err := InitializeServer()
	err = srv.Run()
	if err != nil {
		return
	}
}
