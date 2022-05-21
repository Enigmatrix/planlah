package main

import (
	_ "planlah.sg/backend/docs" // to get generated swagger docs to be enabled
)

func main() {
	srv, err := InitializeServer()
	err = srv.Run()
	if err != nil {
		return
	}
}
