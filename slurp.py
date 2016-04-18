import requests
import credentials

BASE_URL = "http://publicsearch1.chicagopolice.org/api/Arrests/Search?&Take=100&Skip={}"

page = 0
while True:
    response = requests.get(BASE_URL.format(page * 100),
                            auth=(credentials.user,
                                  credentials.password))
    print(response.json())
    break
