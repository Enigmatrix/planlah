package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func GetAttractions() []string {
	return []string{
		"Airport",
		"Art & History",
		"Food",
		"Games",
		"Movies",
		"Nature & Wildlife",
		"Nightlife",
		"Religion",
		"Shopping",
		"Spas",
		"Sports",
		"Studying",
		"Tourism",
		"Transport",
		"Water Activities",
	}
}

func GetFood() []string {
	return []string{
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
	}
}

func GetGenders() []string {
	return []string{
		"Male",
		"Female",
		"Other",
	}
}

func GetTowns() []string {
	return []string{
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
	}
}

type MiscController struct {
	BaseController
}

// Towns godoc
// @Summary Get towns
// @Description Get towns
// @Tags Misc
// @Success 200 {object} []string
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/misc/towns [get]
func (ctr *MiscController) Towns(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, GetTowns())
}

// Gender godoc
// @Summary Get genders
// @Description Get genders
// @Tags Misc
// @Success 200 {object} []string
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/misc/gender [get]
func (ctr *MiscController) Gender(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, GetGenders())
}

// Attractions godoc
// @Summary Get attraction types
// @Description Get attraction types
// @Tags Misc
// @Success 200 {object} []string
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/misc/attractions [get]
func (ctr *MiscController) Attractions(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, GetAttractions())
}

// Food godoc
// @Summary Get food types
// @Description Get food types
// @Tags Misc
// @Success 200 {object} []string
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} ErrorMessage
// @Router /api/misc/food [get]
func (ctr *MiscController) Food(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, GetFood())
}

// Register the routes for this controller
func (ctr *MiscController) Register(router *gin.RouterGroup) {
	group := router.Group("misc")
	group.GET("towns", ctr.Towns)
	group.GET("gender", ctr.Gender)
	group.GET("food", ctr.Food)
	group.GET("attractions", ctr.Attractions)
}
