--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = carpoolvote, pg_catalog;

--
-- Data for Name: params; Type: TABLE DATA; Schema: carpoolvote; Owner: carpool_admins
--

COPY params (name, value) FROM stdin;
input.driver.enabled	true
input.rider.enabled	true
input.helper.enabled	true
api_environment	live
radius.max	100
radius.tolerance	10
outgoing_sms_whitelist.enabled	false
notifications.time.format	HH12:MIam
notifications.date.format	Mon DD
site.base.url	http://carpoolvote.com
\.


--
-- PostgreSQL database dump complete
--

