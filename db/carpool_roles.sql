-- Role: carpool_admins

-- DROP ROLE carpool_admins;

CREATE ROLE carpool_admins
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;


-- Role: carpool_web_role

-- DROP ROLE carpool_web_role;

CREATE ROLE carpool_web_role
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;


-- Role: carpool_role

-- DROP ROLE carpool_role;

CREATE ROLE carpool_role
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT carpool_web_role TO carpool_role;



-- Role: carpool_match_engine

-- DROP ROLE carpool_match_engine;

CREATE ROLE carpool_match_engine LOGIN
  ENCRYPTED PASSWORD 'md515dfbe205495e280d4859e3a43fad938'
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT carpool_role TO carpool_match_engine;
COMMENT ON ROLE carpool_match_engine IS 'Login for the Carpool Vote Match Engine to use to connect to the DB.';


-- Role: carpool_admin

-- DROP ROLE carpool_admin;

CREATE ROLE carpool_admin LOGIN
  ENCRYPTED PASSWORD 'md515dfbe205495e280d4859e3a43fad938'
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT carpool_admins TO carpool_admin;
COMMENT ON ROLE carpool_admin IS 'Carpool Admin User';



-- Role: carpool_web

-- DROP ROLE carpool_web;

CREATE ROLE carpool_web LOGIN
  ENCRYPTED PASSWORD 'md5ab7703c6f13091f819a76bc8ed630bda'
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT carpool_web_role TO carpool_web;
COMMENT ON ROLE carpool_web IS 'For the CarpoolVote Web Application to use (mainly inserts / minimal selects and updates.)';

