from google_images_search import GoogleImagesSearch
import pandas as pd
from tqdm import tqdm

"""This script obtains the network url for attractions and restaurants"""


# you can provide API key and CX using arguments,
# or you can set environment variables: GCS_DEVELOPER_KEY, GCS_CX
gis = GoogleImagesSearch('AIzaSyAeHanRWhE2iIo-BVvCIy4lEhh1B-bEczY', 'cf517b78660ffdb4d')

# define search params
# option for commonly used search param are shown below for easy reference.
# For param marked with '##':
#   - Multiselect is currently not feasible. Choose ONE option only
#   - This param can also be omitted from _search_params if you do not wish to define any value


def get_image_url(name: str) -> str:
    _search_params = {
        'q': name,
        'num': 1,
        'fileType': 'jpg|gif|png',
    }
    # this will only search for images:
    gis.search(search_params=_search_params)
    return gis.results()[0].url

food_links = []
df = pd.read_csv("RestaurantFinalData.csv")

with tqdm(df.iterrows(), total=len(df)) as pbar:
    pbar.set_description("Restaurants")
    for idx, row in pbar:
        link = get_image_url(row.get("name"))
        food_links.append(link)
        pbar.set_postfix_str(link)
        pbar.update(1)

with open("food_links.txt", "w") as f:
    for link in food_links:
        f.write(f"{link}\n")