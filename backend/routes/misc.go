package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

type MiscController struct{}

// Towns godoc
// @Summary Get towns
// @Description Get towns
// @Tags Misc
// @Success 200 {object} []string
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/misc/towns [get]
func (controller MiscController) Towns(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, []string{
		"Ang Mo Kio",
		"Bedok",
		"Bishan",
		"Boon Lay",
		"Bukit Batok",
		"Bukit Merah",
		"Bukit Panjang",
		"Changi",
		"Choa Chu Kang",
		"Clementi",
		"Geylang",
		"Hougang",
		"Jurong",
		"Kallang",
		"Lum Chu Kang",
		"Mandai",
		"Marina",
		"Marine Parade",
		"Newton",
		"Novena",
		"Orchard",
		"Outram",
		"Pasir Ris",
		"Paya Lebar",
		"Pioneer",
		"Punggol",
		"Queenstown",
		"River Valley",
		"Rochor",
		"Seletar",
		"Sembawang",
		"Sengkang",
		"Serangoon",
		"Sungei Kadut",
		"Tampines",
		"Tanglin",
		"Tengah",
		"Toa Payoh",
		"Tuas",
		"Woodlands",
		"Yishun",
	})
}

// Register the routes for this controller
func (controller MiscController) Register(router *gin.RouterGroup) {
	group := router.Group("misc")
	group.GET("towns", controller.Towns)
}
