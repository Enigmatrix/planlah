package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

var genders = []string{
	"Male",
	"Female",
	"Other",
}

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

func (controller MiscController) Gender(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, genders)
}

func (controller MiscController) Food(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, []string{
		"American",
		"Bakeries",
		"Barbecue",
		"Cafe",
		"Chinese",
		"Contemporary",
		"Dessert",
		"Diner",
		"European",
		"Fast food",
		"French",
		"Fusion",
		"Halal",
		"Healthy",
		"Indian",
		"Indonesian",
		"Italian",
		"Japanese",
		"Korean",
		"Kosher",
		"Lebanese",
		"Malaysian",
		"Middle Eastern",
		"Philippine",
		"Pizza",
		"Pubs",
		"Quick Bites",
		"Seafood",
		"Singaporean",
		"Soups",
		"Sri Lankan",
		"Street Food",
		"Sushi",
		"Thai",
		"Vietnamese",
	})
}

// Register the routes for this controller
func (controller MiscController) Register(router *gin.RouterGroup) {
	group := router.Group("misc")
	group.GET("towns", controller.Towns)
	group.GET("gender", controller.Gender)
	group.GET("food", controller.Food)
}
