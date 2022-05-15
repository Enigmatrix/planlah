package main

import (
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

func main() {
	srv := gin.Default()

	registerRoutes(srv)

	// Swagger documentation
	srv.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	err := srv.Run()
	if err != nil {
		return
	}
}
