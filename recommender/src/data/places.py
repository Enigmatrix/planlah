import googlemaps
import config
import json

gmap = googlemaps.Client(key=config.API_KEY)

singapore_centre_lon = 1.3521
singapore_centre_lat = 103.8198

types = [
    "airport",
    "amusement_park",
    "aquarium",
    "art_gallery",
    "bakery",
    "bar",
    "beauty_salon",
    "bicycle_store",
    "book_store",
    "bowling_alley",
    "cafe",
    "campground",
    "casino",
    "city_hall",
    "clothing_store",
    "convenience_store",
    "department_store",
    "florist",
    "furniture_store",
    "gym",
    "hair_care",
    "hardware_store",
    "hindu_temple",
    "home_goods_store",
    "hospital",
    "jewelry_store",
    "library",
    "light_rail_station",
    "liquor_store",
    "lodging",
    "meal_delivery",
    "meal_takeaway",
    "mosque",
    "movie_theater",
    "museum",
    "night_club",
    "painter",
    "park",
    "pet_store",
    "restaurant",
    "rv_park",
    "school",
    "secondary_school",
    "shoe_store",
    "shopping_mall",
    "spa",
    "stadium",
    "store",
    "subway_station",
    "supermarket",
    "tourist_attraction",
    "train_station",
    "transit_station",
    "zoo"
]

for t in types:
    result = gmap.find_place(
        input=t,
        input_type="textquery",
        fields="textsearch"
        # min_price=0,
        # max_price=4,
        # location=(singapore_centre_lon, singapore_centre_lat),
        # radius=49889.7,
        # type=t)
    )
    with open(f"locations/{t}_data.json", "w") as out:
        json.dump(result, out, indent=4)

