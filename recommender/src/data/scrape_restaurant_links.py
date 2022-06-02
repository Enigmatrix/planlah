from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By

"""
Script to scrape restaurant url reviews from TripAdvisor.sg
"""

browser = Chrome()
results = []
i = 0
NUM_PAGES = 428

try:
    for i in range(NUM_PAGES):
        url = ""
        print(i)
        if i == 0:
            url = "https://www.tripadvisor.com/RestaurantSearch-g294265-Singapore.html#EATERY_LIST_CONTENTS"
        else:
            url = f"https://www.tripadvisor.com/RestaurantSearch-g294265-oa{i * 30}-Singapore.html#EATERY_LIST_CONTENTS"
        print(f"Current url: {url}")
        browser.get(url)
        names = browser.find_elements(by=By.CSS_SELECTOR, value="div.OhCyu a")
        for idx, r in enumerate(names):
            results.append(r.get_attribute("href"))
finally:
    browser.close()
    with open("restaurant_review_links.txt", "w") as f:
        for url in results:
            f.write(url + "\n")
