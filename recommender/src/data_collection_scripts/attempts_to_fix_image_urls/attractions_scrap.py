from scrap import search_google
import pandas as pd

if __name__ == '__main__':
    df = pd.read_csv("Attractions.csv")
    infile = open("attraction_links.txt", "r")

    names = df["name"]
    locations = df["location"]

    links = []
    failures = []
    missing = 0
    for idx, line in enumerate(infile.readlines()):
        if line == "\n":
            missing += 1
            # name = names.get(idx) + " " + locations.get(idx)
            # try:
            #     link = search_google(name)
            #     links.append(link)
            # except Exception as e:
            #     failures.append(idx)
            #     links.append("None")

    print(missing)
    # with open("attraction_recovery.txt", "w") as outfile:
    #     for link in links:
    #         outfile.write(f"{link}\n")

# links = []
# # Loops through the list of search input
# with open("failures_v2.txt", "r") as f:
#     with tqdm(f.readlines(), total=len(f.readlines())) as pbar:
#         for line in pbar:
#             i = int(line.strip())
#             name = names.get(i) + locations.get(i)
#             try:
#                 link = search_google(name)
#                 links.append(link)
#             except Exception as e:
#                 print(e)
#
#
# # Creating header for file containing image source link
# with open("failures_recovery.txt", "w") as outfile:
#     for link in links:
#         outfile.write(f"{link}\n")