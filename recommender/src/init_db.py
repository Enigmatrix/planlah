import os

import pandas as pd
from dotenv import load_dotenv
import psycopg2
from psycopg2.errors import UndefinedTable

from db_utils import get_attractions, get_food


def calculate_feature_vector(row: pd.Series, categories):
    vector = []
    n = len(categories)
    for cat in categories:
        if row.get(cat) == 0:
            vector.append(0)
        else:
            vector.append(1 / n)
    return vector


def calculate_attraction_vector(row: pd.Series):
    return calculate_feature_vector(row, get_attractions())


def calculate_food_vector(row: pd.Series):
    return calculate_feature_vector(row, get_food())


def main():
    load_dotenv("../../.env")

    host = os.getenv('DB_HOST')
    user = os.getenv('DB_USER')
    password = os.getenv('DB_PASSWORD')

    url = f"host={host} user={user} password={password}"
    conn = psycopg2.connect(url)

    cur = conn.cursor()
    # Stop if table already exists and has non-zero rows
    try:
        cur.execute("SELECT COUNT(*) "
                    "FROM places")
        result = cur.fetchone()
        if result[0] > 0:
            print("Skipping db_init")
            return
    except UndefinedTable:
        cur.close()
        conn.close()
        print("Rolling back")
        conn = psycopg2.connect(url)
        cur = conn.cursor()
    print("Initializing table places...")
    cur.execute("DROP TYPE IF EXISTS PLACETYPE")
    cur.execute("CREATE TYPE PLACETYPE AS ENUM('attraction', 'restaurant')")
    cur.execute("CREATE TABLE places ("
                "id serial PRIMARY KEY,"
                "name VARCHAR(255) NOT NULL,"
                "location VARCHAR(255) NOT NULL,"
                "position geography NOT NULL,"
                "formatted_address VARCHAR(255) NOT NULL,"
                "image_url TEXT NOT NULL,"
                "about TEXT,"
                "place_type PLACETYPE NOT NULL,"
                "features FLOAT8[] NOT NULL);")
    # PostGis stores geography as lon, lat

    attractions_df = pd.read_csv("data_collection_scripts/AttractionsFinalDataV2.csv")
    for i, row in attractions_df.iterrows():
        cur.execute("INSERT INTO places "
                    "(name, location, position, formatted_address, about, place_type, features, image_url)"
                    "VALUES (%s, %s, ST_MakePoint(%s, %s), %s, %s, 'attraction', %s, %s)",
                    (row.get("name"), row.get("location"), row.get('lon'), row.get('lat'), row.get("formatted_address"),
                     row.get("about"), calculate_attraction_vector(row), row.get('image')))

    restaurants_df = pd.read_csv("data_collection_scripts/RestaurantFinalDataV2.csv")
    for i, row in restaurants_df.iterrows():
        cur.execute("INSERT INTO places "
                    "(name, location, position, formatted_address, about, place_type, features, image_url)"
                    "VALUES (%s, %s, ST_MakePoint(%s, %s), %s, %s, 'restaurant', %s, %s)",
                    (row.get("name"), row.get("location"), row.get("lon"), row.get("lat"), row.get("formatted_address"),
                     row.get("about"), calculate_food_vector(row), row.get('image')))

    conn.commit()
    conn.close()


if __name__ == '__main__':
    main()
