library(RPostgreSQL)
library(flexmix)

con <- RPostgreSQL::dbConnect(RPostgreSQL::PostgreSQL(), dbname="arrests")

bond <- RPostgreSQL::dbGetQuery(con,
   "SELECT * FROM lockup
    LEFT JOIN bond USING (arrest_id)
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

m1 <- glm(ibond ~ felony, data=bond)

m2 <- stepFlexmix(cbind(ibond, 1-ibond) ~ felony | court_date_id,
                  data=bond, k=2,
                  model = FLXMRglm(family='binomial'))
