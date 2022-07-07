v1 = 0
v2 = 0

with open("restaurant_links.txt", "r") as f:
    print(f"Length of v1 = {len(f.readlines())}")
    for line in f.readlines():
        line = line.strip()
        if line != "None":
            v1 += 1

with open("restaurant_links_v2.txt", "r") as f:
    print(f"Length of v2 = {len(f.readlines())}")
    for line in f.readlines():
        line = line.strip()
        if line != "None":
            v2 += 1

TOTAL = 7863
print(f"v1 = {v1}")
print(f"v2 = {v2}")

# Use v1 unless its not present then use v2
v1 = iter(open("restaurant_links.txt").readlines())
v2 = iter(open("restaurant_links_v2.txt").readlines())

v3 = []
failures = []

for i in range(TOTAL):
    v1_link = next(v1).strip()
    v2_link = next(v2).strip()
    if v1_link == "None" and v2_link == "None":
        v3.append("None")
        failures.append(i)
    elif v1_link != "None":
        v3.append(v1_link)
    else:
        v3.append(v2_link)

with open("restaurant_links_v3.txt", "w") as f:
    for line in v3:
        f.write(f"{line}\n")

with open("failures_v2.txt", "w") as f:
    for j in failures:
        f.write(f"{j}\n")

print(f"{len(failures)} failures")



