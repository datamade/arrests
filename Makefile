PG_DB=arrests
define check_relation
 psql -d $(PG_DB) -c "\d $@" > /dev/null 2>&1 ||
endef

.PHONY : load
load_data : slurp tables
	python3 load.py
	-rm pages/*

.PHONY: slurp
slurp :
	python3 slurp.py

.PHONY : tables
tables : arrest arrestee arrest_event arrestee_address arrest_charges \
         charges bond lockup

arrest :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              central_booking INT, \
                              individual_record INT, \
                              arrest_event_id INT, \
                              fbi_code TEXT)"

arrest_event :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_event_id SERIAL PRIMARY KEY, \
                              arrest_time TIMESTAMP, \
                              street_number TEXT, \
                              street_direction TEXT, \
                              street_name TEXT, \
                              beat TEXT, \
                              district TEXT, \
                              area TEXT, \
                              UNIQUE(arrest_time, street_number, street_direction, street_name))"

arrestee :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              individual_record INT, \
                              first_name TEXT, \
                              middle_name TEXT, \
                              last_name TEXT, \
                              age INT, \
                              mugshot_id INT)" 

arrestee_address :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              individual_record INT, \
                              street_number TEXT, \
                              street_direction TEXT, \
                              street_name TEXT, \
                              city TEXT, \
                              state TEXT)"

arrest_charges :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (charge_id INT PRIMARY KEY, \
                              arrest_id INT, \
                              charge_code INT, \
                              line_id INT)"

charges : charges.json
	$(check_relation) (\
            psql -d $(PG_DB) -c \
                "CREATE TABLE $@ (charge_code INT PRIMARY KEY, \
                                  statute TEXT, \
                                  description TEXT, \
                                  type_code TEXT)" & \
            python3 load_charges.py)


bond :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              amount NUMERIC, \
                              type TEXT, \
                              time TIMESTAMP)"

lockup :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              received TIMESTAMP, \
                              released TIMESTAMP)"


charges.json :
	python3 slurp_charges.py

incidents.csv :
	wget -O $@ "https://data.cityofchicago.org/api/views/ijzp-q8t2/rows.csv?accessType=DOWNLOAD"

incidents : incidents.csv
	$(check_relation) csvsql --db postgresql:///arrests --table $@ --insert $< 


arrest_event_incident : incidents arrest_event
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ AS \
             SELECT \"CASE#\", arrest_event_id \
             FROM arrest_event INNER JOIN incidents \
             ON concat_ws(' ', lpad(CASE WHEN length(street_number) < 3 \
                                         THEN 'X' \
                                         ELSE regexp_replace(street_number, '..$$', 'XX') \
                                    END, 5, '0'), street_direction, street_name) = \"BLOCK\" \
                 AND arrest_time - \"DATE  OF OCCURRENCE\" < interval '2 hour' \
                 AND arrest_time - \"DATE  OF OCCURRENCE\" > interval '-1 hour' \
                 AND \"ARREST\" = True"
