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


SET search_path = carpoolvote, pg_catalog;

--
-- Name: distance(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
    x float = 69.1 * (lat2 - lat1);                           
    y float = 69.1 * (lon2 - lon1) * cos(lat1 / 57.3);        
BEGIN                                                     
    RETURN sqrt(x * x + y * y);                               
END  

$$;


ALTER FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) OWNER TO carpool_admins;


--
-- Name: fct_modified_column(); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION carpoolvote.fct_modified_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_updated_ts = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION carpoolvote.fct_modified_column() OWNER TO carpool_admins;



--
-- Name: bordering_state; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE bordering_state (
    stateabbrev1 character(2),
    stateabbrev2 character(2)
);


ALTER TABLE bordering_state OWNER TO carpool_admins;

--
-- Name: driver; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE driver (
    "UUID" character varying(50) DEFAULT gen_random_uuid() NOT NULL,
    "IPAddress" character varying(20),
    "DriverCollectionZIP" character varying(5) NOT NULL,
    "DriverCollectionRadius" integer NOT NULL,
    "AvailableDriveTimesLocal" character varying(2000),
    "DriverCanLoadRiderWithWheelchair" boolean NOT NULL,
    "SeatCount" integer NOT NULL,
    "DriverLicenseNumber" character varying(50),
    "DriverFirstName" character varying(255) NOT NULL,
    "DriverLastName" character varying(255) NOT NULL,
    "DriverEmail" character varying(255),
    "DriverPhone" character varying(20),
    "DrivingOnBehalfOfOrganization" boolean NOT NULL,
    "DrivingOBOOrganizationName" character varying(255),
    "RidersCanSeeDriverDetails" boolean NOT NULL,
    "DriverWillNotTalkPolitics" boolean NOT NULL,
    "ReadyToMatch" boolean DEFAULT true NOT NULL,
    "PleaseStayInTouch" boolean NOT NULL,
    status character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    status_info text,
    "DriverPreferredContact" character varying(50),
    "DriverWillTakeCare" boolean NOT NULL
);


ALTER TABLE driver OWNER TO carpool_admins;

--
-- Name: helper; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE helper (
	"UUID" character varying(50) DEFAULT gen_random_uuid() NOT NULL,
    helpername character varying(100) NOT NULL,
    helperemail character varying(250) NOT NULL,
    helpercapability character varying(500)[],
	status character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    status_info text
);


ALTER TABLE helper OWNER TO carpool_admins;

--
-- Name: match; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE match (
    status character varying(30) DEFAULT 'Proposed'::character varying NOT NULL,
    uuid_driver character varying(50) NOT NULL,
    uuid_rider character varying(50) NOT NULL,
    score smallint DEFAULT 0 NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE match OWNER TO carpool_admins;

--
-- Name: COLUMN match.status; Type: COMMENT; Schema: carpoolvote; Owner: carpool_admins
--

COMMENT ON COLUMN match.status IS '- MatchProposed
- MatchConfirmed
- Rejected,
- Canceled
- Rejected
- Expired';


--
-- Name: match_engine_activity_log; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE match_engine_activity_log (
    start_ts timestamp without time zone NOT NULL,
    end_ts timestamp without time zone NOT NULL,
    evaluated_pairs integer NOT NULL,
    proposed_count integer NOT NULL,
    error_count integer NOT NULL,
    expired_count integer NOT NULL
);


ALTER TABLE match_engine_activity_log OWNER TO carpool_admins;

--
-- Name: match_engine_scheduler; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE match_engine_scheduler (
    need_run_flag boolean
);


ALTER TABLE match_engine_scheduler OWNER TO carpool_admins;

--
-- Name: COLUMN match_engine_scheduler.need_run_flag; Type: COMMENT; Schema: carpoolvote; Owner: carpool_admins
--

COMMENT ON COLUMN match_engine_scheduler.need_run_flag IS 'the matching engine will process records only when need_run_flag is True
The matching engine resets the flag at the end of its execution';


--
-- Name: outgoing_email; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE outgoing_email (
    id integer NOT NULL,
	uuid character varying(50) NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    status character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    recipient character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    body text NOT NULL,
    emission_info text
);


ALTER TABLE outgoing_email OWNER TO carpool_admins;

--
-- Name: outgoing_email_id_seq; Type: SEQUENCE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE SEQUENCE outgoing_email_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE outgoing_email_id_seq OWNER TO carpool_admins;

--
-- Name: outgoing_email_id_seq; Type: SEQUENCE OWNED BY; Schema: carpoolvote; Owner: carpool_admins
--

ALTER SEQUENCE outgoing_email_id_seq OWNED BY outgoing_email.id;


--
-- Name: outgoing_sms; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE outgoing_sms (
    id integer NOT NULL,
	uuid character varying(50) NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    status character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    recipient character varying(20) NOT NULL,
    body text NOT NULL,
    emission_info text
);


ALTER TABLE outgoing_sms OWNER TO carpool_admins;

--
-- Name: outgoing_sms_id_seq; Type: SEQUENCE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE SEQUENCE outgoing_sms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE outgoing_sms_id_seq OWNER TO carpool_admins;

--
-- Name: outgoing_sms_id_seq; Type: SEQUENCE OWNED BY; Schema: carpoolvote; Owner: carpool_admins
--

ALTER SEQUENCE outgoing_sms_id_seq OWNED BY outgoing_sms.id;



--
-- Name: params; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE params (
    name character varying(50) NOT NULL,
    value character varying(400)
);


ALTER TABLE params OWNER TO carpool_admins;

--
-- Name: rider; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE rider (
    "UUID" character varying(50) DEFAULT gen_random_uuid() NOT NULL,
    "IPAddress" character varying(20),
    "RiderFirstName" character varying(255) NOT NULL,
    "RiderLastName" character varying(255) NOT NULL,
    "RiderEmail" character varying(255),
    "RiderPhone" character varying(20),
    "RiderCollectionZIP" character varying(5) NOT NULL,
    "RiderDropOffZIP" character varying(5) NOT NULL,
    "AvailableRideTimesLocal" character varying(2000),
    "TotalPartySize" integer DEFAULT 1 NOT NULL,
    "TwoWayTripNeeded" boolean NOT NULL,
    "RiderIsVulnerable" boolean NOT NULL,
    "RiderWillNotTalkPolitics" boolean NOT NULL,
    "PleaseStayInTouch" boolean NOT NULL,
    "NeedWheelchair" boolean NOT NULL,
    "RiderPreferredContact" character varying(50),
    "RiderAccommodationNotes" character varying(1000),
    "RiderLegalConsent" boolean NOT NULL,
    "ReadyToMatch" boolean DEFAULT true NOT NULL,
    status character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    status_info text,
    "RiderWillBeSafe" boolean NOT NULL,
    "RiderCollectionAddress" character varying(1000),
    "RiderDestinationAddress" character varying(1000)
);


ALTER TABLE rider OWNER TO carpool_admins;

--
-- Name: tz_dst_offset; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE tz_dst_offset (
    timezone text NOT NULL,
    observes_dst character varying(50),
    offset_summer integer,
    offset_fall integer
);


ALTER TABLE tz_dst_offset OWNER TO carpool_admins;

--
-- Name: usstate; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE usstate (
    stateabbrev character(2) NOT NULL,
    statename character varying(50)
);


ALTER TABLE usstate OWNER TO carpool_admins;



CREATE TABLE carpoolvote.sms_whitelist
(
  phone_number character varying(20) NOT NULL,
  CONSTRAINT sms_whitelist_pk PRIMARY KEY (phone_number)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE carpoolvote.sms_whitelist
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.sms_whitelist TO carpool_admins;
GRANT SELECT, UPDATE ON TABLE carpoolvote.sms_whitelist TO carpool_role;
GRANT SELECT ON TABLE carpoolvote.sms_whitelist TO carpool_web_role;
COMMENT ON TABLE carpoolvote.sms_whitelist
  IS 'lists the phone numbers which we can send SMS to';


--
-- Name: vw_drive_offer; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_drive_offer AS
 SELECT driver."UUID",
    driver."DriverLastName",
    driver."DriverPhone",
    driver."DriverEmail",
    driver.status,
    driver.status_info,
    driver.created_ts,
    driver.last_updated_ts,
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."DriverCanLoadRiderWithWheelchair",
    driver."SeatCount",
    driver."DrivingOnBehalfOfOrganization",
    driver."AvailableDriveTimesLocal"
   FROM driver;


ALTER TABLE vw_drive_offer OWNER TO carpool_admins;

--
-- Name: vw_driver_matches; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_driver_matches AS
 SELECT match.status AS "matchStatus",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
    rider."UUID",
    rider."IPAddress",
    rider."RiderFirstName",
    rider."RiderLastName",
    rider."RiderEmail",
    rider."RiderPhone",
    rider."RiderCollectionZIP",
    rider."RiderDropOffZIP",
    rider."AvailableRideTimesLocal",
    rider."TotalPartySize",
    rider."TwoWayTripNeeded",
    rider."RiderIsVulnerable",
    rider."RiderWillNotTalkPolitics",
    rider."PleaseStayInTouch",
    rider."NeedWheelchair",
    rider."RiderPreferredContact",
    rider."RiderAccommodationNotes",
    rider."RiderLegalConsent",
    rider."ReadyToMatch",
    rider.status,
    rider.status_info,
    rider."RiderWillBeSafe",
    rider."RiderCollectionAddress",
    rider."RiderDestinationAddress"
   FROM (match
     JOIN rider ON (((rider."UUID")::text = (match.uuid_rider)::text)));


ALTER TABLE vw_driver_matches OWNER TO carpool_admins;

--
-- Name: vw_ride_request; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_ride_request AS
 SELECT rider."UUID" AS uuid,
    rider."RiderLastName",
    rider."RiderPhone",
    rider."RiderEmail",
    rider.status,
    rider.status_info,
    rider.created_ts,
    rider.last_updated_ts,
    rider."RiderCollectionZIP",
    rider."RiderDropOffZIP",
    rider."TotalPartySize",
    rider."RiderIsVulnerable",
    rider."NeedWheelchair",
    rider."AvailableRideTimesLocal"
   FROM rider;


ALTER TABLE vw_ride_request OWNER TO carpool_admins;

--
-- Name: vw_rider_matches; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_rider_matches AS
 SELECT match.status AS "matchStatus",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
    driver."UUID",
    driver."IPAddress",
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."AvailableDriveTimesLocal",
    driver."DriverCanLoadRiderWithWheelchair",
    driver."SeatCount",
    driver."DriverLicenseNumber",
    driver."DriverFirstName",
    driver."DriverLastName",
    driver."DriverEmail",
    driver."DriverPhone",
    driver."DrivingOnBehalfOfOrganization",
    driver."DrivingOBOOrganizationName",
    driver."RidersCanSeeDriverDetails",
    driver."DriverWillNotTalkPolitics",
    driver."ReadyToMatch",
    driver."PleaseStayInTouch",
    driver.status,
    driver.status_info,
    driver."DriverPreferredContact",
    driver."DriverWillTakeCare"
   FROM (match
     JOIN driver ON (((driver."UUID")::text = (match.uuid_driver)::text)));


ALTER TABLE vw_rider_matches OWNER TO carpool_admins;

--
-- Name: vw_unmatched_drivers; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE vw_unmatched_drivers (
    count bigint,
    zip character varying(5),
    state character(2),
    city character varying(50),
    full_state character varying(50),
    latitude_numeric real,
    longitude_numeric real
);

ALTER TABLE ONLY vw_unmatched_drivers REPLICA IDENTITY NOTHING;


ALTER TABLE vw_unmatched_drivers OWNER TO carpool_admins;

--
-- Name: vw_unmatched_drivers_details; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_unmatched_drivers_details AS
 SELECT driver."UUID",
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."SeatCount",
    driver."AvailableDriveTimesLocal"
   FROM driver
  WHERE (((driver.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text, ('MatchConfirmed'::character varying)::text])) AND (driver."ReadyToMatch" = true));


ALTER TABLE vw_unmatched_drivers_details OWNER TO carpool_admins;

--
-- Name: vw_unmatched_riders; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE vw_unmatched_riders (
    count bigint,
    zip character varying(5),
    state character(2),
    city character varying(50),
    full_state character varying(50),
    latitude_numeric real,
    longitude_numeric real
);

ALTER TABLE ONLY vw_unmatched_riders REPLICA IDENTITY NOTHING;


ALTER TABLE vw_unmatched_riders OWNER TO carpool_admins;

--
-- Name: vw_unmatched_riders_details; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_unmatched_riders_details AS
 SELECT rider."UUID",
    rider."RiderCollectionZIP",
    rider."TotalPartySize",
    rider."NeedWheelchair",
    rider."AvailableRideTimesLocal"
   FROM rider
  WHERE ((rider.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text]));


ALTER TABLE vw_unmatched_riders_details OWNER TO carpool_admins;

--
-- Name: zip_codes; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE zip_codes (
    zip character varying(5) DEFAULT ''::character varying NOT NULL,
    state character(2) DEFAULT ''::bpchar NOT NULL,
    latitude character varying(10) DEFAULT ''::character varying NOT NULL,
    longitude character varying(10) DEFAULT ''::character varying NOT NULL,
    city character varying(50) DEFAULT ''::character varying,
    full_state character varying(50) DEFAULT ''::character varying,
    latitude_numeric real,
    longitude_numeric real,
    latlong point,
    timezone character varying(50) DEFAULT ''::character varying
);


ALTER TABLE zip_codes OWNER TO carpool_admins;

--
-- Name: id; Type: DEFAULT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_email ALTER COLUMN id SET DEFAULT nextval('outgoing_email_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_sms ALTER COLUMN id SET DEFAULT nextval('outgoing_sms_id_seq'::regclass);


--
-- Name: USSTATE_pkey; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY usstate
    ADD CONSTRAINT "USSTATE_pkey" PRIMARY KEY (stateabbrev);


--
-- Name: ZIP_CODES_pkey; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY zip_codes
    ADD CONSTRAINT "ZIP_CODES_pkey" PRIMARY KEY (zip);


--
-- Name: driver_pk; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY driver
    ADD CONSTRAINT driver_pk PRIMARY KEY ("UUID");


--
-- Name: helper_pk; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY helper
    ADD CONSTRAINT helper_pk PRIMARY KEY ("UUID");


--
-- Name: match_engine_activity_pk; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY match_engine_activity_log
    ADD CONSTRAINT match_engine_activity_pk PRIMARY KEY (start_ts);


--
-- Name: match_pkey; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY match
    ADD CONSTRAINT match_pkey PRIMARY KEY (uuid_driver, uuid_rider);


--
-- Name: outgoing_email_pk; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_email
    ADD CONSTRAINT outgoing_email_pk PRIMARY KEY (id);


--
-- Name: outgoing_sms_pk; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_sms
    ADD CONSTRAINT outgoing_sms_pk PRIMARY KEY (id);


--
-- Name: pk_param; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY params
    ADD CONSTRAINT pk_param PRIMARY KEY (name);


--
-- Name: rider_pk; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY rider
    ADD CONSTRAINT rider_pk PRIMARY KEY ("UUID");


--
-- Name: tz_dst_offset_pkey; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY tz_dst_offset
    ADD CONSTRAINT tz_dst_offset_pkey PRIMARY KEY (timezone);


--
-- Name: _RETURN; Type: RULE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE RULE "_RETURN" AS
    ON SELECT TO vw_unmatched_drivers DO INSTEAD  SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM driver driver,
    zip_codes zip_codes
  WHERE (((driver.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text])) AND ((driver."DriverCollectionZIP")::text = (zip_codes.zip)::text))
  GROUP BY zip_codes.zip;


--
-- Name: _RETURN; Type: RULE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE RULE "_RETURN" AS
    ON SELECT TO vw_unmatched_riders DO INSTEAD  SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM rider rider,
    zip_codes zip_codes
  WHERE (((rider.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text])) AND ((rider."RiderCollectionZIP")::text = (zip_codes.zip)::text))
  GROUP BY zip_codes.zip;




--
-- Name: trg_update_match; Type: TRIGGER; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TRIGGER trg_update_match BEFORE UPDATE OF status ON match FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


--
-- Name: trg_update_outgoing_email; Type: TRIGGER; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TRIGGER trg_update_outgoing_email BEFORE UPDATE OF status ON outgoing_email FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


--
-- Name: trg_update_outgoing_sms; Type: TRIGGER; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TRIGGER trg_update_outgoing_sms BEFORE UPDATE OF status ON outgoing_sms FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


--
-- Name: trg_update_websub_driver; Type: TRIGGER; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TRIGGER trg_update_websub_driver BEFORE UPDATE OF status ON driver FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


--
-- Name: trg_update_websub_rider; Type: TRIGGER; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TRIGGER trg_update_websub_rider BEFORE UPDATE OF status ON rider FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


--
-- Name: match_uuid_driver_fkey; Type: FK CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY match
    ADD CONSTRAINT match_uuid_driver_fkey FOREIGN KEY (uuid_driver) REFERENCES driver("UUID") ON DELETE CASCADE;


--
-- Name: match_uuid_rider_fkey; Type: FK CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY match
    ADD CONSTRAINT match_uuid_rider_fkey FOREIGN KEY (uuid_rider) REFERENCES rider("UUID") ON DELETE CASCADE;

--
-- Name: fct_modified_column(); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION fct_modified_column() FROM PUBLIC;
REVOKE ALL ON FUNCTION fct_modified_column() FROM carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_role;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_web_role;





--
-- Name: driver; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE driver FROM PUBLIC;
REVOKE ALL ON TABLE driver FROM carpool_admins;
GRANT ALL ON TABLE driver TO carpool_admins;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE driver TO carpool_role;
GRANT SELECT,INSERT,UPDATE ON TABLE driver TO carpool_web_role;


--
-- Name: helper; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE helper FROM PUBLIC;
REVOKE ALL ON TABLE helper FROM carpool_admins;
GRANT ALL ON TABLE helper TO carpool_admins;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE helper TO carpool_role;
GRANT INSERT ON TABLE helper TO carpool_web_role;


--
-- Name: match; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE match FROM PUBLIC;
REVOKE ALL ON TABLE match FROM carpool_admins;
GRANT ALL ON TABLE match TO carpool_admins;
GRANT ALL ON TABLE match TO carpool_role;
GRANT SELECT,UPDATE ON TABLE match TO carpool_web_role;


--
-- Name: match_engine_activity_log; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE match_engine_activity_log FROM PUBLIC;
REVOKE ALL ON TABLE match_engine_activity_log FROM carpool_admins;
GRANT ALL ON TABLE match_engine_activity_log TO carpool_admins;
GRANT INSERT ON TABLE match_engine_activity_log TO carpool_role;
GRANT SELECT ON TABLE match_engine_activity_log TO carpool_web_role;


--
-- Name: match_engine_scheduler; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE match_engine_scheduler FROM PUBLIC;
REVOKE ALL ON TABLE match_engine_scheduler FROM carpool_admins;
GRANT ALL ON TABLE match_engine_scheduler TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE match_engine_scheduler TO carpool_role;
GRANT UPDATE ON TABLE match_engine_scheduler TO carpool_web_role;


--
-- Name: outgoing_email; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE outgoing_email FROM PUBLIC;
REVOKE ALL ON TABLE outgoing_email FROM carpool_admins;
GRANT ALL ON TABLE outgoing_email TO carpool_admins;
GRANT ALL ON TABLE outgoing_email TO carpool_role;
GRANT INSERT ON TABLE outgoing_email TO carpool_web;


--
-- Name: outgoing_email_id_seq; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE outgoing_email_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE outgoing_email_id_seq FROM carpool_admins;
GRANT ALL ON SEQUENCE outgoing_email_id_seq TO carpool_admins;
GRANT SELECT,USAGE ON SEQUENCE outgoing_email_id_seq TO carpool_web;
GRANT SELECT,USAGE ON SEQUENCE outgoing_email_id_seq TO carpool_role;


--
-- Name: outgoing_sms; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE outgoing_sms FROM PUBLIC;
REVOKE ALL ON TABLE outgoing_sms FROM carpool_admins;
GRANT ALL ON TABLE outgoing_sms TO carpool_admins;
GRANT ALL ON TABLE outgoing_sms TO carpool_role;
GRANT INSERT ON TABLE outgoing_sms TO carpool_web;


--
-- Name: outgoing_sms_id_seq; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE outgoing_sms_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE outgoing_sms_id_seq FROM carpool_admins;
GRANT ALL ON SEQUENCE outgoing_sms_id_seq TO carpool_admins;
GRANT SELECT,USAGE ON SEQUENCE outgoing_sms_id_seq TO carpool_web;
GRANT SELECT,USAGE ON SEQUENCE outgoing_sms_id_seq TO carpool_role;


--
-- Name: params; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE params FROM PUBLIC;
GRANT ALL ON TABLE params TO carpool_admins;
GRANT ALL ON TABLE params TO carpool_role;
GRANT SELECT ON TABLE params TO carpool_web_role;

--
-- Name: rider; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE rider FROM PUBLIC;
REVOKE ALL ON TABLE rider FROM carpool_admins;
GRANT ALL ON TABLE rider TO carpool_admins;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE rider TO carpool_role;
GRANT SELECT,INSERT,UPDATE ON TABLE rider TO carpool_web_role;


--
-- Name: vw_drive_offer; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_drive_offer FROM PUBLIC;
REVOKE ALL ON TABLE vw_drive_offer FROM carpool_admins;
GRANT ALL ON TABLE vw_drive_offer TO carpool_admins;
GRANT SELECT ON TABLE vw_drive_offer TO carpool_role;


--
-- Name: vw_driver_matches; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_driver_matches FROM PUBLIC;
REVOKE ALL ON TABLE vw_driver_matches FROM carpool_admins;
GRANT ALL ON TABLE vw_driver_matches TO carpool_admins;
GRANT SELECT ON TABLE vw_driver_matches TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_driver_matches TO carpool_role;


--
-- Name: vw_ride_request; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_ride_request FROM PUBLIC;
REVOKE ALL ON TABLE vw_ride_request FROM carpool_admins;
GRANT ALL ON TABLE vw_ride_request TO carpool_admins;
GRANT SELECT ON TABLE vw_ride_request TO carpool_role;


--
-- Name: vw_rider_matches; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_rider_matches FROM PUBLIC;
REVOKE ALL ON TABLE vw_rider_matches FROM carpool_admins;
GRANT ALL ON TABLE vw_rider_matches TO carpool_admins;
GRANT SELECT ON TABLE vw_rider_matches TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_rider_matches TO carpool_role;


--
-- Name: vw_unmatched_drivers; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_drivers FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_drivers FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_drivers TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_drivers TO carpool_web_role;
GRANT SELECT ON TABLE vw_unmatched_drivers TO carpool_role;


--
-- Name: vw_unmatched_drivers_details; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_drivers_details FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_drivers_details FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_drivers_details TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_drivers_details TO carpool_role;
GRANT SELECT ON TABLE vw_unmatched_drivers_details TO carpool_web;
GRANT SELECT ON TABLE vw_unmatched_drivers_details TO carpool_web_role;


--
-- Name: vw_unmatched_riders; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_riders FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_riders FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_riders TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_riders TO carpool_web_role;
GRANT SELECT ON TABLE vw_unmatched_riders TO carpool_role;


--
-- Name: vw_unmatched_riders_details; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_riders_details FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_riders_details FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_riders_details TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_riders_details TO carpool_role;
GRANT SELECT ON TABLE vw_unmatched_riders_details TO carpool_web;
GRANT SELECT ON TABLE vw_unmatched_riders_details TO carpool_web_role;


--
-- Name: zip_codes; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE zip_codes FROM PUBLIC;
REVOKE ALL ON TABLE zip_codes FROM carpool_admins;
GRANT SELECT ON TABLE zip_codes TO carpool_web_role;
GRANT ALL ON TABLE zip_codes TO carpool_admins;
GRANT ALL ON TABLE zip_codes TO carpool_role;


--
-- PostgreSQL database dump complete
--

