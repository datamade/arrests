PG_DB=arrests
define check_relation
 psql -d $(PG_DB) -c "\d $@" > /dev/null 2>&1 ||
endef

.PHONY : load
load : slurp arrest arrestee arrestee_address arrest_charges charges bond lockup
	python3 load.py

.PHONY: slurp
slurp :
	python3 slurp.py

arrest :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              central_booking INT, \
                              individual_record INT, \
                              arrest_time TIMESTAMP, \
                              street_number TEXT, \
                              street_direction TEXT, \
                              street_name TEXT, \
                              beat TEXT, \
                              district TEXT, \
                              area TEXT, \
                              fbi_code TEXT)"

arrestee :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              individual_record INT, \
                              first_name TEXT, \
                              middle_name TEXT, \
                              last_name TEXT, \
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

charges :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (charge_code_id INT PRIMARY KEY, \
                              statute INT, \
                              description TEXT, \
                              class_code TEXT, \
                              type_code TEXT)"

bond :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT PRIMARY KEY, \
                              amount NUMERIC, \
                              type TEXT, \
                              date TIMESTAMP)"

lockup :
	$(check_relation) psql -d $(PG_DB) -c \
            "CREATE TABLE $@ (arrest_id INT, \
                              type TEXT, \
                              time TIMESTAMP, \
                              PRIMARY KEY(arrest_id, type))"

