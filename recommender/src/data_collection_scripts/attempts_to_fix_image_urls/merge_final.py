import pandas as pd
"""
Merge v3 and failures_recovery
"""

v3 = iter(open("restaurant_links_v3.txt", "r").readlines())
recovery = iter(open("failures_recovery.txt", "r").readlines())

final_links = []

TOTAL = 7863

for i in range(TOTAL):
    v3_link = next(v3).strip()
    if v3_link == "None":
        recovery_link = next(recovery).strip()
        final_links.append(recovery_link)
    else:
        final_links.append(v3_link)

with open("restaurant_links_final.txt", "w") as outfile:
    for final_link in final_links:
        outfile.write(f"{final_link}\n")

df = pd.read_csv("RestaurantFinalData.csv")
df["image"] = final_links
df.to_csv("RestaurantFinalDataV2.csv")