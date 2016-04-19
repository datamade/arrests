import json
import psycopg2


con = psycopg2.connect(database="arrests")
c = con.cursor()

with open('charges.json') as infile :
    charges = json.load(infile)
    c.executemany("INSERT INTO charges "
                  "VALUES "
                  "(%(Id)s, %(Statute)s, %(Description)s, %(ChargeTypeCd)s)",
                  charges)

con.commit()
con.close()

            
