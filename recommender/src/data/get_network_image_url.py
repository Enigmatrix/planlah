import time

from google_images_search import GoogleImagesSearch
import pandas as pd
from tqdm import tqdm

"""This script obtains the network url for attractions and restaurants"""


# define search params
# option for commonly used search param are shown below for easy reference.
# For param marked with '##':
#   - Multiselect is currently not feasible. Choose ONE option only
#   - This param can also be omitted from _search_params if you do not wish to define any value


def get_image_url(name: str) -> str:
    # you can provide API key and CX using arguments,
    # or you can set environment variables: GCS_DEVELOPER_KEY, GCS_CX
    _search_params = {
        'q': name,
        'num': 2,
        'fileType': 'jpg|gif|png',
        'ignore_urls': 'https://i.ytimg.com/vi',
    }
    gis = GoogleImagesSearch('AIzaSyAeHanRWhE2iIo-BVvCIy4lEhh1B-bEczY', 'cf517b78660ffdb4d')
    # this will only search for images:
    gis.search(search_params=_search_params)
    if len(gis.results()) > 0:
        if "https://i.ytimg.com/vi" in gis.results()[0].url:
            return gis.results()[1].url
        else:
            return gis.results()[0].url
    else:
        return ""


attractions_links = []
df = pd.read_csv("AttractionsFinalData.csv")

i = 0

try:
    with tqdm(df.iterrows(), total=len(df)) as pbar:
        pbar.set_description("Attractions")
        for idx, row in pbar:
            link = get_image_url("Singapore" + row.get("name"))
            attractions_links.append(link)
            print(row.get("name"))
            print(link)
            time.sleep(0.20)
            pbar.update(1)
            i = idx
except TimeoutError:
    print(f"Stopped at {i}")

with open("attraction_links.txt", "a") as f:
    for link in attractions_links:
        f.write(f"{link}\n")
