--- FRESH CARPOOL DB CREATION ---
./create_fresh_carpool_db.sh <DB name>


--- CLEAN UP ---
psql -d <DB name> <  clean_up.sql


--- SCHEMA NAME ---
carpoolvote


--- DATABASE ROLES -----
carpool_admins    : all privileges 
                    contains individual personal users whose role is to maintain the schema
capool_role       : privileges to run the matching engine
                    contains carpool_match_engine database user which should be used to execute the matching engine.
carpool_web_role  : privileges to perform action supported by front end
                    contains the carpool_web database user which should be used by the front end to connect to the database

					
--- TABLES, VIEWS, SEQUENCES, INDEXES ----
echo "\d+ carpoolvote.*" | psql -d <DB name>


--- USER INPUT : drivers, riders, helpers ---
echo "\df carpoolvote.submit_new*" | psql -d <DB name>

submit_new_driver(...,  OUT out_uuid character varying, OUT out_error_code integer, OUT out_error_text text)
submit_new_rider (...,  OUT out_uuid character varying, OUT out_error_code integer, OUT out_error_text text)
submit_new_helper(...,  OUT out_uuid character varying, OUT out_error_code integer, OUT out_error_text text)

-- return codes (out_error_code) : 
-- -1  : ERROR - Generic Error
--  0  : SUCCESS
--  1  : ERROR - Input is disabled
--  2  : ERROR - Input validation

