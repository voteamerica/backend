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
-- Name: user; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE user (
    "UUID" character varying(50) DEFAULT gen_random_uuid() NOT NULL,
    "email" character varying(250) NOT NULL,
    "username" character varying(250) NOT NULL,
    "password" character varying(250) NOT NULL,
    "admin" boolean NOT NULL
);


ALTER TABLE user OWNER TO carpool_admins;

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
    score smallint DEFAULT 0 NOT NULL, -- score column is now used internaly to store the distance between the driver zip code and the rider zip code
	driver_notes text,
	rider_notes text,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON COLUMN carpoolvote.match.score IS 'score column is now used internaly to store the distance between the driver zip code and the rider zip code';


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
	"RiderCollectionStreetNumber" character varying(10),
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
-- Name: user_pk; Type: CONSTRAINT; Schema: carpoolvote; Owner: carpool_admins
--

ALTER TABLE ONLY user
    ADD CONSTRAINT user_pk PRIMARY KEY ("UUID");


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
-- Name: user; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE user FROM PUBLIC;
REVOKE ALL ON TABLE user FROM carpool_admins;
GRANT ALL ON TABLE user TO carpool_admins;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE user TO carpool_role;
GRANT SELECT,INSERT,UPDATE ON TABLE user TO carpool_web_role;


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

