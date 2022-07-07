import os

import pandas as pd
from dotenv import load_dotenv
import psycopg2

from db_utils import get_attractions, get_food

load_dotenv()

host = os.getenv('DB_HOST')
user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')

url = f"host={host} user={user} password={password}"
conn = psycopg2.connect(url)

cur = conn.cursor()
cur.execute("CREATE EXTENSION postgis;")
cur.execute("DROP TABLE IF EXISTS places;")
cur.execute("DROP TYPE IF EXISTS PLACETYPE")
cur.execute("CREATE TYPE PLACETYPE AS ENUM('attraction', 'restaurant')")
cur.execute("CREATE TABLE places ("
            "id serial PRIMARY KEY,"
            "name VARCHAR(255) NOT NULL,"
            "location VARCHAR(255) NOT NULL,"
            "position geography NOT NULL,"
            "formatted_address VARCHAR(255) NOT NULL,"
            "image_url TEXT,"
            "about TEXT,"
            "place_type PLACETYPE NOT NULL,"
            "features FLOAT8[] NOT NULL);")


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


attractions_df = pd.read_csv("AttractionsFinalData.csv")

def get_point(row):
    if row.get("lat") == "nil":
        return None
    else:
        return f"{row.get('lat')} ,{row.get('lon')}"

for i, row in attractions_df.iterrows():
    cur.execute("INSERT INTO places "
                "(name, location, position, formatted_address, about, place_type, features)"
                "VALUES (%s, %s, ST_MakePoint(%s), %s, %s, 'attraction', %s)",
                (row.get("name"), row.get("location"), get_point(row), row.get("formatted_address"),
                 row.get("about"), calculate_attraction_vector(row)))

conn.commit()
conn.close()
