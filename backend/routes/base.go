package routes

import (
	"errors"
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
	"planlah.sg/backend/utils"
)

type BaseController struct {
	Database *data.Database
	Auth     *services.AuthService
	Config   *utils.Config
}

func (ctr *BaseController) AuthUserId(ctx *gin.Context) (uint, error) {
	// this will always succeed, as the rejection will come from go-jwt
	// even before we get here. However, we still check for error in case
	// the spec changes in the future.
	return ctr.Auth.AuthenticatedUserId(ctx), nil
}

func (ctr *BaseController) AuthGroupMember(ctx *gin.Context, grpID uint) (*data.GroupMember, error) {
	userId, err := ctr.AuthUserId(ctx)
	if err != nil {
		return nil, err
	}

	groupMember := ctr.Database.GetGroupMember(userId, grpID)
	if ctr == nil {
		err := errors.New(fmt.Sprintf("user is not a member of group %d", grpID))
		ctx.JSON(http.StatusBadRequest, NewErrorMessage(err.Error()))
		return nil, err
	}
	return groupMember, nil
}
