from bing_image_urls import bing_image_urls

images = []

with open("failures.txt", "r") as f:
    for failure in f.readlines():
        failure = failure.strip()
        print(failure)
        results = bing_image_urls(failure)
        print([r for r in results])
        break
