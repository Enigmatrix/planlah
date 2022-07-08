from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By
import pandas as pd

"""
Script to scrape attraction url reviews from TripAdvisor.sg
"""

browser = Chrome()
results = []
error_logs = []

with open("src/data_collection_scripts/attraction_review_links.txt", "r") as f:
    for idx, url in enumerate(f.readlines()):
        url = url[:-1]
        print(f"{idx}. {url=}")
        browser.get(url)
        result = {}
        # Get name
        try:
            name = browser.find_element(By.CSS_SELECTOR, value="h1.WlYyy cPsXC GeSzT")
            print(name.get_attribute("innerHTML"))
            result["name"] = name.get_attribute("innerHTML")
        except Exception:
            error_logs.append("Failed to get name for " + url)
            result["name"] = url
        # Get location
        try:
            location = browser.find_element(by=By.CSS_SELECTOR, value="div.dIDBU.MJ")
            location = location.get_attribute("innerHTML")\
                .split("<span class=\"WlYyy cacGK Wb\">")[1]\
                .split("</span></button>")[0]
            result["location"] = location
        except Exception:
            error_logs.append("Failed to get location for " + result["name"])
            result["location"] = "nil"
        # Get about
        try:
            about = browser.find_element(by=By.CSS_SELECTOR, value="div.eENph.Gg.A > div.dYtkw > span > div.dCitE._d.MJ > div > div.pIRBV._T.KRIav > div")
            result["about"] = about.get_attribute("innerHTML")
        except Exception:
            error_logs.append("Failed to get about for " + result["name"])
            result["about"] = "nil"
        # Get tags
        try:
            tags = browser.find_element(by=By.CSS_SELECTOR, value="div.pIRBV._T.KRIav")
            result["tags"] = tags.get_attribute("innerHTML")
        except Exception:
            error_logs.append("Failed to get tags for " + result["name"])
        # Get reviews
        try:
            review_rating = browser.find_element(by=By.CSS_SELECTOR, value="div.WlYyy.cPsXC.fksET.cMKSg")
            result["overallRating"] = review_rating.get_attribute("innerHTML")
            review_cnt = browser.find_element(by=By.CSS_SELECTOR, value="span.cfIVb")
            result["overallRatingCnt"] = review_cnt.get_attribute("innerHTML")
        except Exception:
            error_logs.append("Failed to get reviews for " + result["name"])
            result["overallRating"] = "nil"
            result["overallRatingCnt"] = "nil"
        results.append(result)

with open("error_logs_attraction.txt", "w") as f:
    for error_log in error_logs:
        f.write(error_log + "\n")

df = pd.DataFrame(results)
df.to_csv("AttractionRawData.csv")