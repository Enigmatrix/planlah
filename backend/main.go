package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	srv := gin.Default()
	srv.GET("/ping", func(ctx *gin.Context) {
		ctx.JSON(http.StatusOK, gin.H{"message": "pong"})
	})
	srv.Run()
}
