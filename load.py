import json
import psycopg2
import itertools
import glob

con = psycopg2.connect(database="arrests")
c = con.cursor()

for fn in glob.glob('pages/*.json'):
    with open(fn) as infile :
        page = json.load(infile)
        for row in page:
            c.execute("SELECT arrest_event_id "
                      "FROM arrest_event "
                      "WHERE arrest_time = %(Date)s "
                      "AND street_number = %(StreetNo)s "
                      "AND street_direction = %(StreetDirection)s "
                      "AND street_name = %(StreetName)s",
                      row)
            arrest_event_id = c.fetchone()
            if arrest_event_id is None:
                c.execute("INSERT INTO arrest_event "
                          "(arrest_time, street_number, street_direction, "
                          " street_name, beat, district, area) "
                          "VALUES "
                          "(%(Date)s, %(StreetNo)s, %(StreetDirection)s, "
                          " %(StreetName)s, %(Beat)s, %(District)s, %(Area)s)"
                          "RETURNING arrest_event_id",
                      row)
                arrest_event_id = c.fetchone()                
                con.commit()
                
            row['arrest_event_id'] = arrest_event_id[0]
            if 'IrNo' not in row:
                row['IrNo'] = None
            c.execute("INSERT INTO arrest "
                      "VALUES "
                      "(%(Id)s, %(CbNo)s, %(IrNo)s, %(arrest_event_id)s, "
                      " %(FBICode)s) "
                      "ON CONFLICT DO NOTHING",
                      row)

        c.executemany("INSERT INTO arrestee "
                      "VALUES "
                      "(%(Id)s, %(IrNo)s, %(FirstName)s, %(MiddleName)s, "
                      " %(LastName)s, %(Age)s, %(MugshotId)s) "
                      "ON CONFLICT DO NOTHING",
                      page)

        c.executemany("INSERT INTO bond "
                      "VALUES "
                      "(%(Id)s, %(BondAmt)s, %(BondTypeCd)s, %(BondDate)s) "
                      "ON CONFLICT DO NOTHING",
                      (row for row in page if row['BondDate']))
        c.executemany("INSERT INTO lockup "
                      "VALUES "
                      "(%(Id)s, %(ReceivedInLockup)s, %(ReleasedFromLockup)s) "
                      "ON CONFLICT (arrest_id) "
                      "DO UPDATE "
                      "SET received = %(ReceivedInLockup)s, "
                      "    released = %(ReleasedFromLockup)s",
                      page)
        c.executemany("INSERT INTO arrest_charges "
                      "VALUES "
                      "(%(Id)s, %(ArrestId)s, %(ChargeCodeId)s, %(LineId)s) "
                      "ON CONFLICT DO NOTHING",
                      itertools.chain.from_iterable(row["Charges"] for row in page))
        con.commit()                     

            
    
con.close()

