from flask import Flask, request, Response
from http import HTTPStatus

from db import filter_places, get_user
from db_utils import get_user_features
from distance import calculate_similarity_metric
import init_db


recommender = Flask(__name__)

TOP_K = 5


@recommender.route("/recommend/", methods=["GET"])
def recommend():
    """
    The only interface for our recommender.
    Takes in userid, longitude, latitude and returns the top 5 places.
    We first find the userid and return earlier if it does not exist.
    Then based on the flag, we either query restaurants or attractions and filter by radius of 2km
    Then we calculate the similarity metric (currently cosine similarity) between the user profile
    and the places feature vector.
    Then we sort and return top 5.
    """
    userid = request.args.get("userid")
    lon = request.args.get("lon")
    lat = request.args.get("lat")
    place_type = request.args.get("place_type")
    user = get_user(userid)
    if user is None:
        return Response(status=HTTPStatus.BAD_REQUEST, response="user does not exist")

    if place_type != "restaurant" and place_type != "attraction":
        return Response(status=HTTPStatus.BAD_REQUEST, response="invalid place_type")

    places = filter_places(place_type, lon, lat)
    if places is None:
        return Response(status=HTTPStatus.BAD_REQUEST, response="could not find places")

    places = calculate_similarity_metric(places, get_user_features(user, place_type))

    places.sort(key=lambda x: x[1], reverse=True)
    results = {
        "results": [idx for idx, _ in places[:TOP_K]]
    }
    return results


if __name__ == '__main__':
    init_db.main()
    recommender.run(host="0.0.0.0")