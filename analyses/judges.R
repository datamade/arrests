library(RPostgreSQL)
library(flexmix)

con <- RPostgreSQL::dbConnect(RPostgreSQL::PostgreSQL(), dbname="arrests")

distributions <- RPostgreSQL::dbGetQuery(con,
    "SELECT SUM((type IS NOT NULL and type = 'IBOND')::INT)/COUNT(*)::NUMERIC
     FROM lockup
     LEFT JOIN bond
     USING (arrest_id)
     INNER JOIN
     (SELECT arrest_id
      FROM arrest_charges
      INNER JOIN charges
      USING (charge_code)
      GROUP BY arrest_id
      HAVING bool_or(type_code IS NOT NULL AND type_code = 'F')) AS felonies
     USING (arrest_id)
     WHERE released IS NOT NULL
     GROUP BY released::DATE")

bond <- RPostgreSQL::dbGetQuery(con,
    "SELECT * FROM lockup
     LEFT JOIN bond
     USING (arrest_id)
     INNER JOIN
     (SELECT arrest_id,
             bool_or(type_code IS NOT NULL AND type_code = 'F') AS felony
      FROM arrest_charges
      INNER JOIN charges
      USING (charge_code)
      GROUP BY arrest_id) AS felonies
     USING (arrest_id)
     WHERE released IS NOT NULL")

bond$ibond <- !is.na(bond$type) & bond$type == 'IBOND'
bond$court_date <- as.Date(bond$released)
bond$court_date_id <- as.numeric(bond$court_date)
bond$day_of_week <- weekdays(bond$court_date)
bond <- bond[bond$felony,]

table(bond$day_of_week, bond$ibond)

m1 <- glm(ibond ~ felony + day_of_week, data=bond)

m2 <- stepFlexmix(cbind(ibond, 1-ibond) ~ felony | court_date_id,
                  data=bond, k=2,
                  model = FLXMRglm(family='binomial'))
