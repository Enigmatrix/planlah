package routes

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/juju/errors"
	"github.com/samber/lo"
	"go.uber.org/zap"
	"io"
	"net/http"
	"strconv"
)

type FriendlyError interface {
	error
	Kind() string
}

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
func Body[T any](ctx *gin.Context, dto *T) bool {
	err := ctx.ShouldBindJSON(&dto)
	if err == nil {
		return false
	}

	processValidationError[T](ctx, err)
	return true
}

// Form binds the POST multipart form of the request to the DTO, and gives a
// descriptive error back for debugging purposes
func Form[T any](ctx *gin.Context, dto *T) bool {
	err := ctx.ShouldBind(&dto)
	if err == nil {
		return false
	}

	processValidationError[T](ctx, err)
	return true
}

// Uri binds the uri of the request to the DTO, and gives a
// descriptive error back for debugging purposes
func Uri[T any](ctx *gin.Context, dto *T) bool {
	err := ctx.ShouldBindUri(&dto)
	if err == nil {
		return false
	}

	processValidationError[T](ctx, err)
	return true
}

// Query binds the query parameters of the request to the DTO, and gives a
// descriptive error back for debugging purposes
func Query[T any](ctx *gin.Context, dto *T) bool {
	err := ctx.ShouldBindQuery(&dto)
	if err == nil {
		return false
	}

	processValidationError[T](ctx, err)
	return true
}

func processValidationError[T any](ctx *gin.Context, err error) {
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
}

func handleDbError(ctx *gin.Context, err error) bool {
	if err == nil {
		return false
	}

	_ = ctx.AbortWithError(http.StatusInternalServerError, err)

	return true
}

func handleHubError(logger *zap.Logger, err error) bool {
	if err == nil {
		return false
	}
	logger.Warn("hub send err", zap.Error(err))
	return true
}

func convertPageToUInt(page string) (uint, error) {
	pageNo, err := strconv.Atoi(page)
	if err != nil {
		return 0, errors.New("Failed to convert page to uint")
	}
	return uint(pageNo), nil
}
