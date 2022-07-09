import re

import string

import selenium.common.exceptions
from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By
from bs4 import BeautifulSoup, SoupStrainer
import pandas as pd
import requests
import httplib2
import urllib3

"""
Script to scrape image urls from TripAdvisor.sg
"""

browser = Chrome()
results = []
error_logs = []

# RestaurantFinalData is a subset of restaurant review links. Therefore, advance to the next line in restaurant final
# data_collection_scripts until we obtain the corresponding review link, then we scrape the network image.

df = pd.read_csv("RestaurantFinalData2.csv")
headers = {"User-Agent": "Mozilla/5.0 (X11; CrOS x86_64 12871.102.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.141 Safari/537.36"}
session = requests.Session()


def extract_name(review_link: str) -> str:
    name = review_link.split("Reviews-")[1].split("-Singapore.html")[0]
    return clean(name.replace("_", "").replace(" ", ""))


def clean(dirty: str):
    """Remove all punctuation"""
    return dirty.translate(str.maketrans('', '', string.punctuation)).replace(" ", "")


with open("restaurant_review_links.txt", "r") as links:
    iter_links = iter(links.readlines())
    try:
        for idx, row in df.iterrows():
            name = row.get("name")
            name = clean(name)
            print(name)
            link = next(iter_links)
            link_name = extract_name(link)
            print(f"{link_name=}")
            while link_name not in name:
                link = next(iter_links)
                link_name = extract_name(link)
            browser.get(link)
            # Click on view all images
            # try:
            #     browser.find_element(by=By.CSS_SELECTOR, value="#taplc_resp_rr_photo_mosaic_0 > div > div.photos_and_contact_links_container.ui_column.is-8-widescreen.is-custom-desktop.is-12-tablet.is-12-mobile > div.photo_mosaic_and_all_photos_banner > div.see_all_banner > span.details").click()
            # except selenium.common.exceptions.NoSuchElementException:
            #     browser.find_element(by=By.CSS_SELECTOR, value="taplc_resp_rr_photo_mosaic_0 > div > div.photos_and_contact_links_container.ui_column.is-12 > div.photo_mosaic_and_all_photos_banner > div.mosaic_photos > div.mobile_flex_container.full_width > div.see_all_count_wrap > span > span.details").click()
            browser.find_element(by=By.CSS_SELECTOR, value="div.see_all_count_wrap")
            soup = BeautifulSoup(browser.page_source, parser="lxml")
            for image_src in soup.findAll("img"):
                if image_src["src"].endswith(".jpg") and "media" in image_src["src"]:
                    results.append(image_src["src"])
    except StopIteration:
        print(f"Restaurant Name = {name}")


with open("image_urls.txt", "w") as f:
    for image_src in results:
        f.write(f"{image_src}\n")