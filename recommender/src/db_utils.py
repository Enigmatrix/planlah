def get_attractions():
    return [
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
    ]


def get_food():
    return [
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
    ]


def get_user_features(user: tuple, place_type: str):
    if place_type == "attraction":
        return user[0]
    else:
        return user[1]


@DeprecationWarning
def user_tuple_to_dict(user: tuple):
    return {
        'id': user[0],
        'username': user[1],
        'name': user[2],
        'gender': user[3],
        'town': user[4],
        'firebase_uid': user[5],
        'image_link': user[6],
        'attractions': user[7],
        'food': user[8],
    }


@DeprecationWarning
def place_tuple_to_features(place: tuple):
    return place[-1]