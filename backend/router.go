package main

import (
	"github.com/gin-gonic/gin"
	users "planlah.sg/backend/routes"
)

func registerRoutes(srv *gin.Engine) {
	api := srv.Group("api")
	{
		users.Register(api)
	}
}
