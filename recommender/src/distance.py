import numpy as np
from numpy.linalg import norm


def cosine_similarity(place: np.ndarray, user: np.ndarray):
    """
    norm along axis = 1 <-> norm along the rows or each place

    Args:
        place: shape = (#places, #place_feature_vector)
        user: shape = (#feature_vector)

    Returns: Cosine similarity score that ranges from 0 to 1
    """
    return np.dot(place, user) / (norm(place, axis=1) * norm(user))


def calculate_similarity_metric(places:  list[tuple[int, list[float]]], user: tuple):
    """
    Args:
        places: list of (id, features) where features: list of floats
        user: list of floats

    Returns: list of (idx, similarity_score)

    """
    ids = [idx for idx, _ in places]
    places_features = np.stack([features for _, features in places], axis=0)
    user_features = np.asarray(user)
    similarities = cosine_similarity(places_features, user_features)
    return [(idx, similarity) for idx, similarity in zip(ids, similarities)]
    # return np.stack([ids, similarities], axis=1)


if __name__ == '__main__':
    restaurants = [
        (2487,
         [0.0, 0.0, 0.0, 0.02857142857142857, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
        (2620,
         [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
        (2621,
         [0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
        (2774,
         [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0,
          0.0]),
        (2936,
         [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02857142857142857, 0.0, 0.02857142857142857, 0.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    ]

    user = (0.14285714285714285,0.14285714285714285,0.14285714285714285,0.14285714285714285,0.14285714285714285,0.14285714285714285,0.14285714285714285,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    calculate_similarity_metric(restaurants, user)
