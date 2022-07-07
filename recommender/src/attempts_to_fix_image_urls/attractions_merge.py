import pandas as pd
"""Merge attraction_recovery and attraction_links"""

original = iter(open("attraction_links.txt", "r").readlines())
recovery = iter(open("attraction_recovery.txt", "r").readlines())

final_links = []

TOTAL = 1828

for i in range(TOTAL):
    og = next(original)
    if og == "\n":
        recovery_link = next(recovery).strip()
        final_links.append(recovery_link)
    else:
        final_links.append(og.strip())

with open("attraction_links_final.txt", "w") as outfile:
    for final_link in final_links:
        outfile.write(f"{final_link}\n")

df = pd.read_csv("Attractions.csv")
df["image"] = final_links
df.to_csv("AttractionsFinalDataV2.csv")