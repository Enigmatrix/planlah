import pandas as pd
from tqdm import tqdm

from bing_image_urls import bing_image_urls

"""This script obtains the network url for restaurants separated for my sanity"""

# 6032
# 6323

i = 6323
df = pd.read_csv("RestaurantFinalData.csv")
restaurants_links = []
FAILURES = []


def fail(url: str):
    FAILURES.append(url)
    return "None"


def convert(name: str) -> str:
    parts = name.split(" ")
    return "-".join(parts)


def attempt(restaurant_name, search_results) -> str:
    if len(search_results) == 0:
        return ""
    # Loop two times, we prioritize URLs that contain the restaurant name under the assumption that they are better
    # quality pictures
    for search_result in search_results:
        if convert(restaurant_name) in search_result:
            return search_result
    for search_result in search_results:
        if "tripadvisor" in search_result:
            return search_result
    return ""


try:
    with tqdm(df.iterrows(), total=len(df)) as pbar:
        pbar.set_description("restaurants")
        total = 0
        success = 0
        for idx, row in pbar:
            if idx < i:
                continue
            # Try without tripadvisor first and if no good results, search tripadvisor
            result = attempt(row.get("name"), bing_image_urls(row.get("name") + " " + row.get("location"), limit=50))
            if result == "":
                result = attempt(row.get("name"), bing_image_urls("tripadvisor" + " " + row.get("name"), limit=50))
            if result == "":
                link = fail(row.get("name"))
            else:
                link = result
                success += 1
            total += 1
            restaurants_links.append(link)
            pbar.update(1)
            pbar.set_description(row.get("name") + f"; {success}/{total}")
            pbar.set_postfix_str(link)
            i = idx
except Exception as e:
    print(e)
    print(f"Stopped at {i}")

with open("restaurant_links_v2.txt", "a") as f:
    for link in restaurants_links:
        f.write(f"{link}\n")

with open("failures_v2.txt", "a") as f:
    for link in FAILURES:
        f.write(f"{link}\n")