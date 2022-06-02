from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By
import pandas as pd

"""
Script to scrape attraction url reviews from TripAdvisor.sg
"""

browser = Chrome()
results = []

with open("attraction_review_links.txt", "r") as f:
    for idx, url in enumerate(f.readlines()):
        url = url[:-1]
        print(f"{idx}. {url=}")
        try:
            browser.get(url)
            result = {}
            # Get name
            name = browser.find_element(by=By.CSS_SELECTOR, value="h1.WlYyy.cPsXC.GeSzT")
            result["name"] = name.get_attribute("innerHTML")
            # Get location
            try:
                location = browser.find_element(by=By.CSS_SELECTOR, value="div.dIDBU.MJ")
                location = location.get_attribute("innerHTML")\
                    .split("<span class=\"WlYyy cacGK Wb\">")[1]\
                    .split("</span></button>")[0]
                result["location"] = location
            except Exception:
                result["location"] = ""
            # Get about
            try:
                about = browser.find_element(by=By.CSS_SELECTOR, value="div.eENph.Gg.A > div.dYtkw > span > div.dCitE._d.MJ > div > div.pIRBV._T.KRIav > div")
                result["about"] = about.get_attribute("innerHTML")
            except Exception:
                result["about"] = ""
            # Get tags
            tags = browser.find_element(by=By.CSS_SELECTOR, value="div.pIRBV._T.KRIav")
            result["tags"] = tags.get_attribute("innerHTML")
            # Get reviews
            review_rating = browser.find_element(by=By.CSS_SELECTOR, value="div.WlYyy.cPsXC.fksET.cMKSg")
            result["overallRating"] = review_rating.get_attribute("innerHTML")
            review_cnt = browser.find_element(by=By.CSS_SELECTOR, value="span.cfIVb")
            result["overallRatingCnt"] = review_cnt.get_attribute("innerHTML")

            results.append(result)
        except Exception:
            print(f"Encountered issue loading {url=}")

df = pd.DataFrame(results)
df.to_csv("AttractionRawData.csv")