import pandas as pd

results = [
    "DSDad",
    "Dasdasda",
    "DSasdsadasdadasd",
]

with open("restaurant_review_links.txt", "w") as f:
    for url in results:
        f.write(url + "\n")
