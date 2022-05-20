package routes

import (
	"errors"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"io"
	"net/http"
)

type ErrorMessage struct {
	Message string `json:"message" binding:"required"`
}

func Body[T any](ctx *gin.Context, dto *T) error {
	err := ctx.ShouldBindJSON(&dto)
	if err == nil {
		return nil
	}

	// TODO make this only run in debug
	var validationErrors validator.ValidationErrors

	if errors.As(err, &validationErrors) {
		validationMessage := make([]string, len(validationErrors))
		for i, fieldError := range validationErrors {
			validationMessage[i] = fieldError.Error()
		}
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "validation", "validation": validationMessage})
	} else if err == io.EOF {
		message := fmt.Sprintf("Body of type %T expected", dto)
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "missingBody", "message": message})
	} else {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "unknown", "message": err.Error()})
	}
	return err
}
