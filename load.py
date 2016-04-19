import json
import psycopg2
import os

con = psycopg2.connect(database="arrests")
c = con.cursor()

arrest_keys = ("Id", "CbNo", "IrNo", "Date", "StreetNo", "StreetDirection",
               "StreetName", "Beat", "District", "Area", "FBICode")

for fn in os.listdir('pages'):
    with open('pages/' + fn) as infile :
        page = json.load(infile)
        try:
            c.executemany("INSERT INTO arrest VALUES (%(Id)s, %(CbNo)s, %(IrNo)s, %(Date)s, %(StreetNo)s, %(StreetDirection)s, %(StreetName)s, %(Beat)s, %(District)s, %(Area)s, %(FBICode)s)",
                      vars_list=page)
        except psycopg2.IntegrityError:
            con.rollback()
        else:
            con.commit()
con.close()
