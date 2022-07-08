import os

import psycopg2


def get_db_connection():
    host = os.getenv('DB_HOST')
    user = os.getenv('DB_USER')
    password = os.getenv('DB_PASSWORD')

    url = f"host={host} user={user} password={password}"
    conn = psycopg2.connect(url)
    return conn


def get_user(userid):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT attractions, food FROM users WHERE id = %s", (userid,))
    user = cur.fetchone()
    if user is None:
        return None
    return user


def filter_places(place_type: str, lon: str, lat: str):
    """
    Refer to https://postgis.net/workshops/postgis-intro/geography.html
    """
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, features "
                "FROM places "
                "WHERE ST_DWithin(position, ST_SetSRID(ST_Point(%s, %s), 4326), 2000) "
                "AND place_type = %s ",
                (lon, lat, place_type))
    results = cur.fetchall()
    cur.close()
    conn.close()
    return results
