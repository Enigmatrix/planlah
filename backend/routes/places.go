package routes

import (
	"encoding/json"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"go.uber.org/zap"
	"io"
	"net/http"
	"planlah.sg/backend/data"
)

type PlacesController struct {
	BaseController
}

type SearchForPlacesDto struct {
	Pagination
	Query string `form:"query" binding:"required"`
}

type RecommendPlacesDto struct {
	data.Point
	PlaceType data.PlaceType `form:"placeType" binding:"required"`
}

type RecommendPlacesResultDto struct {
	Results []uint `json:"results" binding:"required"`
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
// @Description Increment the {page} variable to view the next (by default 10) users.
// @Param query query SearchForPlacesDto true "body"
// @Tags Places
// @Security JWT
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
// @Security JWT
// @Success 200 {object} []PlaceDto
// @Failure 400 {object} ErrorMessage
// @Failure 401 {object} services.AuthError
// @Router /api/places/recommend [get]
func (ctr *PlacesController) Recommend(ctx *gin.Context) {
	userId := ctr.AuthUserId(ctx)

	var dto RecommendPlacesDto
	if Query(ctx, &dto) {
		return
	}

	if dto.PlaceType != data.Attraction && dto.PlaceType != data.Restaurant {
		FailWithMessage(ctx, "invalid placeType")
		return
	}

	resp, err := http.Get(fmt.Sprintf("%s/recommend/?userid=%d&lon=%f&lat=%f&place_type=%s",
		ctr.Config.RecommenderUrl, userId, dto.Longitude, dto.Latitude, dto.PlaceType))
	if err != nil {
		// TODO handle error
		return
	}
	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			ctr.Logger.Warn("close recommender req body", zap.Error(err))
		}
	}(resp.Body)

	var response RecommendPlacesResultDto

	if resp.StatusCode == http.StatusOK {
		err = json.NewDecoder(resp.Body).Decode(&response)
		if err != nil {
			// TODO handle error
			return
		}
	} else if resp.StatusCode == http.StatusBadRequest {
		strErr, err := io.ReadAll(resp.Body)
		if err != nil {
			// TODO handle error
			return
		}
		ctr.Logger.Warn("recommender badReq",
			zap.String("err", string(strErr)))
		return
	} else if resp.StatusCode == http.StatusInternalServerError {
		ctr.Logger.Error("recommender internalServerError, see recommender logs")
	}

	places, err := ctr.Database.GetPlaces(response.Results)
	if err != nil {
		handleDbError(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, ToPlaceDtos(places))
}

// Register the routes for this controller
func (ctr *PlacesController) Register(router *gin.RouterGroup) {
	places := router.Group("places")
	places.GET("search", ctr.Search)
	places.GET("recommend", ctr.Recommend)
}
