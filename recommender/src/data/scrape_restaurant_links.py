from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By
import time

"""
Script to scrape restaurant url reviews from TripAdvisor.sg
"""

browser = Chrome()
results = []

try:
    i = 0
    SLEEP_INTERVAL = 10
    # Click all buttons except Delivery only
    url = "https://www.tripadvisor.com.sg/Restaurants-g294265-Singapore.html"
    browser.get(url)
    # Open in maximized
    browser.maximize_window()
    # Click the Show More button
    browser.find_element(by=By.CSS_SELECTOR, value="#component_48 > div > div:nth-child(2) > div.czbRE > div.eduCX.Cj.b.S4.H3._S > span.fdmYH").click()
    # The Restaurant button is clicked by default
    # Click Quick Bites
    browser.find_element(By.CSS_SELECTOR, value="#component_48 > div > div:nth-child(2) > div.czbRE > div:nth-child(2) > div > label > div > span > span").click()
    # Sleep 5 seconds to allow website to load or else we encounter cannot find CSS selector exception
    time.sleep(SLEEP_INTERVAL)
    # Click Dessert
    browser.find_element(By.CSS_SELECTOR, value="#component_48 > div > div:nth-child(2) > div.czbRE > div:nth-child(3) > div > label > div > span > span").click()
    time.sleep(SLEEP_INTERVAL)
    # Click Coffee & Tea
    browser.find_element(By.CSS_SELECTOR, value="#component_48 > div > div:nth-child(2) > div.czbRE > div:nth-child(4) > div > label > div > span > span").click()
    time.sleep(SLEEP_INTERVAL)
    # Click Bakeries
    browser.find_element(By.CSS_SELECTOR, value="#component_48 > div > div:nth-child(2) > div.czbRE > div:nth-child(5) > div > label > div > span > span").click()
    time.sleep(SLEEP_INTERVAL)
    # Click Bars & Pubs
    browser.find_element(By.CSS_SELECTOR, value="#component_48 > div > div:nth-child(2) > div.czbRE > div:nth-child(6) > div > label > div > span > span").click()
    time.sleep(SLEEP_INTERVAL)
    # Click Speciality Food Market
    browser.find_element(By.CSS_SELECTOR, value="#component_48 > div > div:nth-child(2) > div.czbRE > div:nth-child(7) > div > label").click()
    time.sleep(SLEEP_INTERVAL)
    # # According to TripAdvisor, there are 13,961 results in total
    # # Given 30 restaurant cards per page, there should be 466 page navigations in total
    NUM_PAGES = 466
    for i in range(NUM_PAGES):
        names = browser.find_elements(by=By.CSS_SELECTOR, value="div.OhCyu a")
        for idx, r in enumerate(names):
            print(r.get_attribute("href"))
            results.append(r.get_attribute("href"))
        # Go next
        browser.find_element(by=By.CSS_SELECTOR, value="#EATERY_LIST_CONTENTS > div.deckTools.btm > div > a.nav.next.rndBtn.ui_button.primary.taLnk").click()
        time.sleep(SLEEP_INTERVAL)
finally:
    browser.close()
    with open("restaurant_review_links.txt", "w") as f:
        for url in results:
            f.write(url + "\n")
