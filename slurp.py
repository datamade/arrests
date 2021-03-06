import datetime
import scrapelib
import credentials
import json

BASE_URL = "http://publicsearch1.chicagopolice.org/api/Arrests/Search?&StartDate={date}&Take=100&Skip={{skip}}"
outfile = 'pages/{}.json'
        
cache = scrapelib.cache.FileCache('_cache')        
s = scrapelib.Scraper(requests_per_minute=30)
s.cache_storage = cache

start_date = datetime.date.today() - datetime.timedelta(days=4)
url = BASE_URL.format(date=start_date)

page = 0
while True:
    print(page)
    response = s.get(url.format(skip=page * 100),
                     auth=(credentials.user,
                           credentials.password))
    with open(outfile.format(page), 'w') as out:
        json.dump(response.json(), out)
    if len(response.json()) < 100:
        break
    page += 1
        
