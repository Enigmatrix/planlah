from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By
import pandas as pd

"""
Script to scrape restaurant url reviews from TripAdvisor.sg
"""

browser = Chrome()
results = []

with open("restaurant_review_links.txt", "r") as f:
    for idx, url in enumerate(f.readlines()):
        url = url[:-1]
        print(f"{idx}. {url=}")
        try:
            browser.get(url)
            result = {}
            # Get name
            result["name"] = browser.find_element(by=By.CSS_SELECTOR, value="h1.fHibz").get_attribute("innerHTML")
            # Find location
            result["location"] = browser.find_element(by=By.CSS_SELECTOR, value="span.brMTW").get_attribute("innerHTML")
            # Get working hours
            # Click the button first
            browser.find_element(by=By.CSS_SELECTOR, value="span.dyeJW.bcYVS").click()
            working_hours_elements = browser.find_elements(by=By.CSS_SELECTOR, value="div.ferBE.f")
            working_hours = []
            for working_hours_element in working_hours_elements:
                working_hours.append(working_hours_element.get_attribute("innerHTML"))
            result["working_hours"] = ",".join(working_hours)
            # print(browser.find_element(by=By.CSS_SELECTOR, value=""))
            # Get price range
            try:
                price_range = browser.find_element(by=By.CSS_SELECTOR, value="div.cfvAV").get_attribute("innerHTML")
                if "SGD&nbsp;" in price_range:
                    price_ranges = price_range.split(" - ")
                    min_price = price_ranges[0].split("SGD&nbsp;")[1].strip()
                    max_price = price_ranges[1].split("SGD&nbsp;")[1].strip()
                    result["price_range"] = min_price + "-" + max_price
                else:
                    result["price_range"] = ""
            except Exception:
                # Indicates that no price range was specified by TripAdvisor
                result["price_range"] = ""
            # Get tags
            tags_element = browser.find_element(by=By.CSS_SELECTOR, value="span.dyeJW.VRlVV")
            tags = []
            for idx, tag in enumerate(tags_element.find_elements(by=By.CSS_SELECTOR, value="a.drUyy")):
                # Skip the first tag because it is a $$$ sign
                if idx == 0:
                    continue
                tags.append(tag.get_attribute("innerHTML"))
            result["tags"] = ",".join(tags)
            # Get TripAdvisor ratings
            # It is ordered by Food, Service, Value, Atmosphere
            ratings_elements = browser.find_elements(by=By.CSS_SELECTOR, value="span.cwxUN")
            # Any of the ratings might not be present
            try:
                result["foodRating"] = ratings_elements[0]\
                    .get_attribute("innerHTML")\
                    .split("ui_bubble_rating bubble_")[1][:2]
            except Exception:
                result["foodRating"] = ""
            try:
                result["serviceRating"] = ratings_elements[1]\
                    .get_attribute("innerHTML")\
                    .split("ui_bubble_rating bubble_")[1][:2]
            except Exception:
                result["serviceRating"] = ""
            try:
                result["valueRating"] = ratings_elements[2]\
                    .get_attribute("innerHTML")\
                    .split("ui_bubble_rating bubble_")[1][:2]
            except Exception:
                result["valueRating"] = ""
            try:
                result["atmosphereRating"] = ratings_elements[3]\
                    .get_attribute("innerHTML")\
                    .split("ui_bubble_rating bubble_")[1][:2]
            except Exception:
                result["atmosphereRating"] = ""
            # Get overall TripAdvisor rating
            overall_rating = browser.find_element(by=By.CSS_SELECTOR, value="span.fdsdx")\
                .get_attribute("innerHTML").split("<!-- -->")[0]
            result["overallRating"] = overall_rating
            # Get number of TripAdvisor ratings
            result["overallRatingCnt"] = browser.find_element(by=By.CSS_SELECTOR, value="a.dUfZJ")\
                .get_attribute("innerHTML").split(" reviews")[0]
            results.append(result)
        except Exception:
            print(f"Encountered issue loading {url=}")

df = pd.DataFrame(results)
df.to_csv("RestaurantRawData.csv")
