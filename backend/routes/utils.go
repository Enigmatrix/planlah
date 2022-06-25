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

func NewErrorMessage(msg string) ErrorMessage {
	return ErrorMessage{Message: msg}
}

// Body binds the POST body of the request to the DTO, and gives a
// descriptive error back for debugging purposes
func Body[T any](ctx *gin.Context, dto *T) error {
	err := ctx.ShouldBindJSON(&dto)
	if err == nil {
		return nil
	}

	return processValidationError[T](ctx, err)
}

// Form binds the POST multipart form of the request to the DTO, and gives a
// descriptive error back for debugging purposes
func Form[T any](ctx *gin.Context, dto *T) error {
	err := ctx.ShouldBind(&dto)
	if err == nil {
		return nil
	}

	return processValidationError[T](ctx, err)
}

// Uri binds the uri of the request to the DTO, and gives a
// descriptive error back for debugging purposes
func Uri[T any](ctx *gin.Context, dto *T) error {
	err := ctx.ShouldBindUri(&dto)
	if err == nil {
		return nil
	}

	return processValidationError[T](ctx, err)
}

// Query binds the query parameters of the request to the DTO, and gives a
// descriptive error back for debugging purposes
func Query[T any](ctx *gin.Context, dto *T) error {
	err := ctx.ShouldBindQuery(&dto)
	if err == nil {
		return nil
	}
	return processValidationError[T](ctx, err)
}

func processValidationError[T any](ctx *gin.Context, err error) error {
	// TODO make this only run in debug
	var validationErrors validator.ValidationErrors

	if errors.As(err, &validationErrors) {
		validationMessage := make([]string, len(validationErrors))
		for i, fieldError := range validationErrors {
			validationMessage[i] = fieldError.Error()
		}
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "validation", "validation": validationMessage})
	} else if err == io.EOF {
		var d T
		message := fmt.Sprintf("Body of type %T expected", d)
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "missingBody", "message": message})
	} else {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "unknown", "message": err.Error()})
	}
	return err

}
