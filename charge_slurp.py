import credentials
import json
import requests

response = requests.get('http://publicsearch1.chicagopolice.org/api/Arrests/GetChargeCodes?Take=3000',
                        auth=(credentials.user,
                              credentials.password))

with open('charges.json', 'w') as out:
    json.dump(response.json(), out)

