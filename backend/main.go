package main

import (
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	_ "planlah.sg/backend/docs"
)

func main() {
	srv := gin.Default()

	registerRoutes(srv)

	// Swagger documentation
	srv.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	srv.Run()
}
