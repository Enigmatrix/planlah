from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By

"""
Script to scrape attraction url reviews from TripAdvisor.sg
"""

browser = Chrome()
results = []
NUM_PAGES = 105

try:
    for i in range(NUM_PAGES):
        url = ""
        if i == 0:
            url = "https://www.tripadvisor.com/Attractions-g294265-Activities-a_allAttractions.true-Singapore.html"
        else:
            url = f"https://www.tripadvisor.com/Attractions-g294265-Activities-oa{i * 30}-Singapore.html"
        print(f"Current url: {url}")
        browser.get(url)
        names = browser.find_elements(by=By.CSS_SELECTOR, value="a.FmrIP._R.w._Z.P0.M0.Gm.ddFHE")
        for idx, r in enumerate(names):
            print(r.get_attribute("href"))
            results.append(r.get_attribute("href"))
finally:
    browser.close()
    with open("attraction_review_links.txt", "w") as f:
        for url in results:
            f.write(url + "\n")
