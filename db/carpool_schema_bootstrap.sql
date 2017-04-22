--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
--SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
--SET row_security = off;


--
-- Name: carpoolvote; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA carpoolvote;


ALTER SCHEMA carpoolvote OWNER TO postgres;


--
-- Name: carpoolvote; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA carpoolvote FROM PUBLIC;
REVOKE ALL ON SCHEMA carpoolvote FROM postgres;
GRANT ALL ON SCHEMA carpoolvote TO postgres;
GRANT USAGE ON SCHEMA carpoolvote TO carpool_role;
GRANT ALL ON SCHEMA carpoolvote TO carpool_admins;
GRANT USAGE ON SCHEMA carpoolvote TO carpool_web_role;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA carpoolvote;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = carpoolvote, pg_catalog;

