package main

import (
	"context"
	firebase "firebase.google.com/go/v4"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"log"
	_ "planlah.sg/backend/docs" // to get generated swagger docs to be enabled
	"planlah.sg/backend/routes"
)

func main() {
	srv := gin.Default()
	firebaseApp, err := firebase.NewApp(context.Background(), nil)
	if err != nil {
		log.Fatalf("Firebase app initialization failed: %v", err)
	}
	user := routes.UserController{
		FirebaseApp: firebaseApp,
	}
	auth := routes.AuthController{
		FirebaseApp: firebaseApp,
	}

	api := srv.Group("api")

	user.Register(api)
	auth.Register(api)

	// Swagger documentation
	srv.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	err = srv.Run()
	if err != nil {
		return
	}
}
