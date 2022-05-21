package main

import (
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"log"
	_ "planlah.sg/backend/docs" // to get generated swagger docs to be enabled
	"planlah.sg/backend/routes"
	"planlah.sg/backend/services"
)

func main() {
	srv := gin.Default()

	user := routes.UserController{}

	authSvc, err := services.NewAuthService()
	if err != nil {
		log.Fatalf("Firebase Auth Service initialization failed: %v", err)
	}

	auth := routes.AuthController{
		AuthService: authSvc,
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
