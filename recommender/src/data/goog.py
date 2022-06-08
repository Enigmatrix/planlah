import googlemaps
import pandas as pd
import config
import yaml

client = googlemaps.Client(key=config.API_KEY)
df = pd.read_csv("RestaurantProcessedData.csv")
dataset = []

for idx, row in df.iterrows():
    name = row["name"] + ", " + row["location"]
    res_1 = client.find_place(
        name,
        "textquery"
    )
    if res_1["status"] == "OK":
        res = client.place(
            res_1["candidates"][0]["place_id"],
            fields=[
                "business_status",
                "formatted_address",
                "geometry/location/lat",
                "geometry/location/lng",
                "icon",
                "name",
                "place_id",
                "type",
                "opening_hours",
                "price_level",
                "rating",
                "user_ratings_total",
            ]
        )
        print(yaml.dump(res, default_flow_style=False))
        break



