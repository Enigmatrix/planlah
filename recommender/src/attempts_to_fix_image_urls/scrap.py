import pandas as pd
from selenium import webdriver
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time
from tqdm import tqdm

"""
Seems to be the best performing method so far
https://medium.com/@dian.octaviani/method-1-4-automation-of-google-image-scraping-using-selenium-3972ea3aa248
"""

df = pd.read_csv("RestaurantFinalData.csv")
names = df["name"]
locations = df["location"]
chromedriver = ChromeDriverManager().install()


# i = 270

def search_google(search_query):
    search_url = f"https://www.google.com/search?site=&tbm=isch&source=hp&biw=1873&bih=990&q={search_query}"

    options = webdriver.ChromeOptions()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-gpu')
    options.add_argument('--headless')
    options.add_argument('--disable-web-security')
    options.add_argument('--allow-running-insecure-content')
    options.add_argument('--allow-cross-origin-auth-prompt')

    browser = webdriver.Chrome(chromedriver, options=options)

    # Open browser to begin search
    browser.get(search_url)

    # CSS Selector for the 1st image that appears in Google
    img_box = browser.find_element(by=By.CSS_SELECTOR, value="div.bRMDJf.islir")
    # Click on the thumbnail
    img_box.click()

    # CSS Selector of the image display
    fir_img = browser.find_element(by=By.CSS_SELECTOR, value="div.qdnLaf.isv-id.b0vFpe > div > a > img")

    # Wait between interaction
    time.sleep(0.25)
    fir_img.click()

    # Retrieve attribute of src from the element
    img_src = fir_img.get_attribute('src')

    return img_src


links = []
# Loops through the list of search input
with open("failures_v2.txt", "r") as f:
    with tqdm(f.readlines(), total=len(f.readlines())) as pbar:
        for line in pbar:
            i = int(line.strip())
            name = names.get(i) + locations.get(i)
            try:
                link = search_google(name)
                links.append(link)
            except Exception as e:
                print(e)


# Creating header for file containing image source link
with open("failures_recovery.txt", "w") as outfile:
    for link in links:
        outfile.write(f"{link}\n")


