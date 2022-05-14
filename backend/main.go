package main

import (
	"github.com/gin-gonic/gin"
	swaggerfiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

func main() {
	srv := gin.Default()

	registerRoutes(srv)

	// Swagger documentation
	srv.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))

	err := srv.Run()
	if err != nil {
		return
	}
}
