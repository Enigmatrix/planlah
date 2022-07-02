import pandas as pd
import requests
import urllib.parse

base_url = "https://nominatim.openstreetmap.org/search/?q="
suffix = "?format=json"

df = pd.read_csv("AttractionsFinalData.csv")

for i, row in df.iterrows():
    print(i)
    url = base_url + urllib.parse.quote(row.get("name") + ",Singapore") + suffix
    print(url)
    response = requests.get(url)
    print(response)
    if response.status_code == 200:
        response = response.json()
        if not row.get("location", False):
            df.at[i, "location"] = response[0]["display_name"]
        if not row.get("lat", False):
            df.at[i, "lat"] = response[0]["lat"]
        if not row.get("lon", False):
            df.at[i, "lon"] = response[0]["lon"]
        if not row.get("formatted_address", False):
            df.at[i, "formatted_address"] = response[0]["display_name"]
    else:
        print("Error")

df.to_csv("HELLO.csv")