package routes

import (
	"errors"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/samber/lo"
	"io"
	"net/http"
)

type ErrorKind struct {
	Kind string `json:"kind" binding:"required"`
}

type ErrorMessage struct {
	ErrorKind
	Message string `json:"message" binding:"required"`
}

type ValidationErrorMessage struct {
	ErrorKind
	Fields []string `json:"fields" binding:"required"`
}

var friendlyError = ErrorKind{Kind: "FRIENDLY_ERROR"}
var genericError = ErrorKind{Kind: "GENERIC_ERROR"}
var validationFieldsError = ErrorKind{Kind: "VALIDATION_FIELDS_ERROR"}
var validationMissingBodyError = ErrorKind{Kind: "VALIDATION_MISSING_BODY_ERROR"}
var validationGenericError = ErrorKind{Kind: "VALIDATION_GENERIC_ERROR"}

func FailWithError(ctx *gin.Context, err error) {
	FailWithMessage(ctx, err.Error())
}

func FailWithMessage(ctx *gin.Context, msg string) {
	ctx.JSON(http.StatusBadRequest, ErrorMessage{ErrorKind: friendlyError, Message: msg})
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
	var validationErrors validator.ValidationErrors
	if errors.As(err, &validationErrors) {
		fields := lo.Map(validationErrors, func(fld validator.FieldError, _ int) string {
			return fld.Error()
		})
		ctx.JSON(http.StatusBadRequest, ValidationErrorMessage{ErrorKind: validationFieldsError, Fields: fields})
	} else if err == io.EOF {
		var d T
		message := fmt.Sprintf("Body of type %T expected", d)
		ctx.JSON(http.StatusBadRequest, ErrorMessage{ErrorKind: validationMissingBodyError, Message: message})
	} else {
		ctx.JSON(http.StatusBadRequest, ErrorMessage{ErrorKind: validationGenericError, Message: err.Error()})
	}
	return err
}
