package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"net/http"
	"planlah.sg/backend/data"
	"time"
)

type PlacesController struct {
	BaseController
}

type SearchForPlacesDto struct {
	Pagination
	Query string `uri:"query" binding:"required"`
}

type RecommendPlacesDto struct {
	data.Place
	Time time.Time `uri:"time" binding:"required"`
}

type PlaceDto struct {
	ID               uint           `json:"id" binding:"required"`
	Name             string         `json:"name" binding:"required"`
	Location         string         `json:"location" binding:"required"`
	Position         data.Point     `json:"position" binding:"required"`
	FormattedAddress string         `json:"formattedAddress" binding:"required"`
	ImageLink        string         `json:"imageLink" binding:"required"`
	About            string         `json:"about" binding:"required"`
	PlaceType        data.PlaceType `json:"placeType" binding:"required"`
}

func ToPlaceDto(place *data.Place) PlaceDto {
	return PlaceDto{
		ID:               place.ID,
		Name:             place.Name,
		Location:         place.Location,
		Position:         place.Position,
		FormattedAddress: place.FormattedAddress,
		ImageLink:        place.ImageUrl,
		About:            place.About,
		PlaceType:        place.PlaceType,
	}
}

func ToPlaceDtos(places []data.Place) []PlaceDto {
	return lo.Map(places, func(t data.Place, _ int) PlaceDto {
		return ToPlaceDto(&t)
	})
}

// Search godoc
// @Summary Search for places
// @Description Search for places given the name
// @Param query query SearchForPlacesDto true "body"
// @Tags Places
// @Success 200 {object} []PlaceDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/places/search [get]
func (ctr *PlacesController) Search(ctx *gin.Context) {
	var dto SearchForPlacesDto
	if Query(ctx, &dto) {
		return
	}

	places, err := ctr.Database.SearchForPlaces(dto.Query, dto.Page)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToPlaceDtos(places))
}

// Recommend godoc
// @Summary Recommend places
// @Description Recommend places for this user given the location & time
// @Param query query RecommendPlacesDto true "body"
// @Tags Places
// @Success 200 {object} []PlaceDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/places/recommend [get]
func (ctr *PlacesController) Recommend(ctx *gin.Context) {
	var dto RecommendPlacesDto
	if Query(ctx, &dto) {
		return
	}

	// TODO forward the request to recommender service

	// ctx.JSON(http.StatusOK, ToPlaceDtos(places))
}

// Register the routes for this controller
func (ctr *PlacesController) Register(router *gin.RouterGroup) {
	places := router.Group("places")
	places.GET("search", ctr.Search)
	places.GET("recommend", ctr.Recommend)
}