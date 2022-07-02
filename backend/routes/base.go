package routes

import (
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"planlah.sg/backend/data"
	"planlah.sg/backend/services"
	"planlah.sg/backend/utils"
)

type BaseController struct {
	Database *data.Database
	Auth     *services.AuthService
	Config   *utils.Config
	Logger   *zap.Logger
}

func (ctr *BaseController) AuthUserId(ctx *gin.Context) uint {
	// this will always succeed, as the rejection will come from go-jwt
	// even before we get here.
	return ctr.Auth.AuthenticatedUserId(ctx)
}

func (ctr *BaseController) AuthGroupMember(ctx *gin.Context, grpID uint) *data.GroupMember {
	userId := ctr.AuthUserId(ctx)
	grpMember, err := ctr.Database.GetGroupMember(userId, grpID)

	if err != nil {
		handleDbError(ctx, err)
		return grpMember
	}

	if grpMember == nil {
		FailWithMessage(ctx, "user is not a member of this group")
		return nil
	}

	return grpMember
}
