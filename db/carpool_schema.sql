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

--
-- Name: nov2016; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA nov2016;


ALTER SCHEMA nov2016 OWNER TO postgres;

--
-- Name: stage; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA stage;


ALTER SCHEMA stage OWNER TO postgres;

--
-- Name: SCHEMA stage; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA stage IS 'Staging Area';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = nov2016, pg_catalog;

--
-- Name: cancel_ride_by_rider(integer, integer); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION cancel_ride_by_rider("RiderID" integer DEFAULT '-1'::integer, "RequestedRideID" integer DEFAULT '-1'::integer) RETURNS integer
    LANGUAGE sql
    AS $_$

UPDATE nov2016.requested_ride
   SET  "Active" = '0'::bit(1)
       ,"ModifiedTimestamp" = now() at time zone 'utc'
       ,"ModifiedBy" = 'CancelRider'
 WHERE requested_ride."RiderID" = $1
 ;
 
 SELECT 1;
 

$_$;


ALTER FUNCTION nov2016.cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) OWNER TO carpool_admins;

--
-- Name: FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer); Type: COMMENT; Schema: nov2016; Owner: carpool_admins
--

COMMENT ON FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) IS 'Performs actions necessary to ensure that the appropriate parties know that the need for the scheduled ride has evaporated.';


--
-- Name: distance(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
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


ALTER FUNCTION nov2016.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) OWNER TO carpool_admins;

SET search_path = public, pg_catalog;

--
-- Name: distance(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: carpool_admins
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


ALTER FUNCTION public.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) OWNER TO carpool_admins;

SET search_path = nov2016, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: driver; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE driver (
    "DriverID" integer NOT NULL,
    "Name" character varying(255),
    "Phone" character varying(20),
    "Email" character varying(255),
    "RideDate" date,
    "RideTimeStart" time with time zone,
    "RideTimeEnd" time with time zone,
    "State" character varying(255),
    "City" character varying(255),
    "Origin" character varying(255),
    "RiderDestination" character varying(2000),
    "Seats" integer,
    "Notes" character varying(2000),
    "CreatedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "CreatedBy" character varying(255) DEFAULT 'SYSTEM'::character varying,
    "ModifiedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "ModifiedBy" character varying(255) DEFAULT 'SYSTEM'::character varying,
    "EmailValidated" boolean DEFAULT false NOT NULL,
    "DriverHasInsurance" boolean DEFAULT false NOT NULL,
    "DriverWheelchair" boolean DEFAULT false NOT NULL,
    "Active" boolean DEFAULT true NOT NULL
);


ALTER TABLE driver OWNER TO carpool_admins;

--
-- Name: DRIVER_DriverID_seq; Type: SEQUENCE; Schema: nov2016; Owner: carpool_admins
--

CREATE SEQUENCE "DRIVER_DriverID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "DRIVER_DriverID_seq" OWNER TO carpool_admins;

--
-- Name: DRIVER_DriverID_seq; Type: SEQUENCE OWNED BY; Schema: nov2016; Owner: carpool_admins
--

ALTER SEQUENCE "DRIVER_DriverID_seq" OWNED BY driver."DriverID";


--
-- Name: proposed_match; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE proposed_match (
    "ProposedMatchID" integer NOT NULL,
    "DriverID" integer NOT NULL,
    "RiderID" integer NOT NULL,
    "RideID" integer NOT NULL,
    "MatchStatusID" integer NOT NULL,
    "MatchedByEngine" character varying(20) DEFAULT 'UnknownEngine 1.0'::character varying NOT NULL,
    "Active" bit(1) DEFAULT B'1'::bit(1) NOT NULL,
    "CreatedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "CreatedBy" character varying(255) DEFAULT 'SYSTEM'::character varying,
    "ModifiedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "ModifiedBy" character varying(255) DEFAULT 'SYSTEM'::character varying
);


ALTER TABLE proposed_match OWNER TO carpool_admins;

--
-- Name: PROPOSED_MATCH_ProposedMatchID_seq; Type: SEQUENCE; Schema: nov2016; Owner: carpool_admins
--

CREATE SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "PROPOSED_MATCH_ProposedMatchID_seq" OWNER TO carpool_admins;

--
-- Name: PROPOSED_MATCH_ProposedMatchID_seq; Type: SEQUENCE OWNED BY; Schema: nov2016; Owner: carpool_admins
--

ALTER SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" OWNED BY proposed_match."ProposedMatchID";


--
-- Name: requested_ride; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE requested_ride (
    "RideID" integer NOT NULL,
    "RiderID" integer NOT NULL,
    "RideDate" date NOT NULL,
    "RideTimeStart" time with time zone NOT NULL,
    "RideTimeEnd" time with time zone NOT NULL,
    "Origin" character varying(255) NOT NULL,
    "OriginZIP" character varying(10),
    "RiderDestination" character varying(2000),
    "DestinationZIP" character varying(10),
    "Capability" character varying(255),
    "SeatsNeeded" integer,
    "WheelChairSpacesNeeded" integer,
    "RideTypeID" integer,
    "DriverID" integer NOT NULL,
    "DriverAcceptedTimeStamp" timestamp with time zone,
    "Active" bit(1) DEFAULT B'1'::bit(1) NOT NULL,
    "CreatedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "CreatedBy" character varying(255) DEFAULT 'SYSTEM'::character varying,
    "ModifiedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "ModifiedBy" character varying(255) DEFAULT 'SYSTEM'::character varying
);


ALTER TABLE requested_ride OWNER TO carpool_admins;

--
-- Name: REQUESTED_RIDE_RideID_seq; Type: SEQUENCE; Schema: nov2016; Owner: carpool_admins
--

CREATE SEQUENCE "REQUESTED_RIDE_RideID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "REQUESTED_RIDE_RideID_seq" OWNER TO carpool_admins;

--
-- Name: REQUESTED_RIDE_RideID_seq; Type: SEQUENCE OWNED BY; Schema: nov2016; Owner: carpool_admins
--

ALTER SEQUENCE "REQUESTED_RIDE_RideID_seq" OWNED BY requested_ride."RideID";


--
-- Name: rider; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE rider (
    "RiderID" integer NOT NULL,
    "Name" character varying(255) NOT NULL,
    "Phone" character varying(20),
    "Email" character varying(255),
    "EmailValidated" bit(1) DEFAULT B'0'::bit(1) NOT NULL,
    "State" character varying(255),
    "City" character varying(255),
    "Notes" character varying(2000),
    "DataEntryPoint" character varying(200) DEFAULT 'Manual Entry'::character varying,
    "VulnerablePopulation" bit(1) DEFAULT B'1'::bit(1) NOT NULL,
    "NeedsWheelChair" bit(1) DEFAULT B'1'::bit(1) NOT NULL,
    "Active" bit(1) DEFAULT B'1'::bit(1) NOT NULL,
    "CreatedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "CreatedBy" character varying(255) DEFAULT 'SYSTEM'::character varying,
    "ModifiedTimestamp" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "ModifiedBy" character varying(255) DEFAULT 'SYSTEM'::character varying
);


ALTER TABLE rider OWNER TO carpool_admins;

--
-- Name: RIDER_RiderID_seq; Type: SEQUENCE; Schema: nov2016; Owner: carpool_admins
--

CREATE SEQUENCE "RIDER_RiderID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "RIDER_RiderID_seq" OWNER TO carpool_admins;

--
-- Name: RIDER_RiderID_seq; Type: SEQUENCE OWNED BY; Schema: nov2016; Owner: carpool_admins
--

ALTER SEQUENCE "RIDER_RiderID_seq" OWNED BY rider."RiderID";


--
-- Name: bordering_state; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE bordering_state (
    stateabbrev1 character(2),
    stateabbrev2 character(2)
);


ALTER TABLE bordering_state OWNER TO carpool_admins;

--
-- Name: helper; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE helper (
);


ALTER TABLE helper OWNER TO carpool_admins;

--
-- Name: match_status; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE match_status (
    "MatchStatusID" integer NOT NULL,
    "MatchStatusName" character varying(255) NOT NULL
);


ALTER TABLE match_status OWNER TO carpool_admins;

--
-- Name: match_status_MatchStatusID_seq; Type: SEQUENCE; Schema: nov2016; Owner: carpool_admins
--

CREATE SEQUENCE "match_status_MatchStatusID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "match_status_MatchStatusID_seq" OWNER TO carpool_admins;

--
-- Name: match_status_MatchStatusID_seq; Type: SEQUENCE OWNED BY; Schema: nov2016; Owner: carpool_admins
--

ALTER SEQUENCE "match_status_MatchStatusID_seq" OWNED BY match_status."MatchStatusID";


--
-- Name: usstate; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE usstate (
    stateabbrev character(2) NOT NULL,
    statename character varying(50)
);


ALTER TABLE usstate OWNER TO carpool_admins;

--
-- Name: zip_codes; Type: TABLE; Schema: nov2016; Owner: carpool_admins
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
    latlong point
);


ALTER TABLE zip_codes OWNER TO carpool_admins;

--
-- Name: zipcode_dist; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE zipcode_dist (
    "ZIPCODE_FROM" character(5) NOT NULL,
    "ZIPCODE_TO" character(5) NOT NULL,
    "DISTANCE_IN_MILES" numeric(10,2) DEFAULT 999.00
);


ALTER TABLE zipcode_dist OWNER TO carpool_admins;

--
-- Name: zipcode_geo; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE zipcode_geo (
    "ZIPCODE" character(5) NOT NULL,
    "CITY" character varying(255) NOT NULL,
    "STATE" character(2) NOT NULL,
    "GEO_LAT" double precision NOT NULL,
    "GET_LONG" double precision NOT NULL,
    "GEO_POINT" point
);


ALTER TABLE zipcode_geo OWNER TO carpool_admins;

SET search_path = stage, pg_catalog;

--
-- Name: websubmission_driver; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_driver (
    "TimeStamp" timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    "IPAddress" character varying(20),
    "DriverCollectionZIP" character varying(5) NOT NULL,
    "DriverCollectionRadius" integer NOT NULL,
    "AvailableDriveTimesJSON" character varying(2000),
    "DriverCanLoadRiderWithWheelchair" boolean DEFAULT false NOT NULL,
    "SeatCount" integer DEFAULT 1,
    "DriverHasInsurance" boolean DEFAULT false NOT NULL,
    "DriverInsuranceProviderName" character varying(255),
    "DriverInsurancePolicyNumber" character varying(50),
    "DriverLicenseState" character(2),
    "DriverLicenseNumber" character varying(50),
    "DriverFirstName" character varying(255) NOT NULL,
    "DriverLastName" character varying(255) NOT NULL,
    "PermissionCanRunBackgroundCheck" boolean DEFAULT false NOT NULL,
    "DriverEmail" character varying(255),
    "DriverPhone" character varying(20),
    "DriverAreaCode" integer,
    "DriverEmailValidated" boolean DEFAULT false NOT NULL,
    "DriverPhoneValidated" boolean DEFAULT false NOT NULL,
    "DrivingOnBehalfOfOrganization" boolean DEFAULT false NOT NULL,
    "DrivingOBOOrganizationName" character varying(255),
    "RidersCanSeeDriverDetails" boolean DEFAULT false NOT NULL,
    "DriverWillNotTalkPolitics" boolean DEFAULT false NOT NULL,
    "ReadyToMatch" boolean DEFAULT false NOT NULL,
    "PleaseStayInTouch" boolean DEFAULT false NOT NULL
);


ALTER TABLE websubmission_driver OWNER TO carpool_admins;

--
-- Name: websubmission_helper; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_helper (
    "timestamp" timestamp without time zone NOT NULL
);


ALTER TABLE websubmission_helper OWNER TO carpool_admins;

--
-- Name: websubmission_rider; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_rider (
    "CreatedTimeStamp" timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    "IPAddress" character varying(20),
    "RiderFirstName" character varying(255) NOT NULL,
    "RiderLastName" character varying(255) NOT NULL,
    "RiderEmail" character varying(255),
    "RiderPhone" character varying(20),
    "RiderAreaCode" integer,
    "RiderEmailValidated" boolean DEFAULT false NOT NULL,
    "RiderPhoneValidated" boolean DEFAULT false NOT NULL,
    "RiderVotingState" character(2) NOT NULL,
    "RiderCollectionZIP" character varying(5) NOT NULL,
    "RiderDropOffZIP" character varying(5) NOT NULL,
    "AvailableRideTimesJSON" character varying(2000),
    "WheelchairCount" integer,
    "NonWheelchairCount" integer,
    "TotalPartySize" integer,
    "TwoWayTripNeeded" boolean DEFAULT false NOT NULL,
    "RiderPreferredContactMethod" integer,
    "RiderIsVulnerable" boolean DEFAULT false NOT NULL,
    "DriverCanContactRider" boolean DEFAULT false NOT NULL,
    "RiderWillNotTalkPolitics" boolean DEFAULT false NOT NULL,
    "ReadyToMatch" boolean DEFAULT false NOT NULL,
    "PleaseStayInTouch" boolean DEFAULT false NOT NULL
);


ALTER TABLE websubmission_rider OWNER TO carpool_admins;

SET search_path = nov2016, pg_catalog;

--
-- Name: DriverID; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY driver ALTER COLUMN "DriverID" SET DEFAULT nextval('"DRIVER_DriverID_seq"'::regclass);


--
-- Name: MatchStatusID; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY match_status ALTER COLUMN "MatchStatusID" SET DEFAULT nextval('"match_status_MatchStatusID_seq"'::regclass);


--
-- Name: ProposedMatchID; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY proposed_match ALTER COLUMN "ProposedMatchID" SET DEFAULT nextval('"PROPOSED_MATCH_ProposedMatchID_seq"'::regclass);


--
-- Name: RideID; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY requested_ride ALTER COLUMN "RideID" SET DEFAULT nextval('"REQUESTED_RIDE_RideID_seq"'::regclass);


--
-- Name: RiderID; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY rider ALTER COLUMN "RiderID" SET DEFAULT nextval('"RIDER_RiderID_seq"'::regclass);


--
-- Name: DRIVER_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY driver
    ADD CONSTRAINT "DRIVER_pkey" PRIMARY KEY ("DriverID");


--
-- Name: PROPOSED_MATCH_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY proposed_match
    ADD CONSTRAINT "PROPOSED_MATCH_pkey" PRIMARY KEY ("ProposedMatchID");


--
-- Name: REQUESTED_RIDE_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY requested_ride
    ADD CONSTRAINT "REQUESTED_RIDE_pkey" PRIMARY KEY ("RideID");


--
-- Name: RIDER_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY rider
    ADD CONSTRAINT "RIDER_pkey" PRIMARY KEY ("RiderID");


--
-- Name: USSTATE_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY usstate
    ADD CONSTRAINT "USSTATE_pkey" PRIMARY KEY (stateabbrev);


--
-- Name: ZIPCODE_DIST_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY zipcode_dist
    ADD CONSTRAINT "ZIPCODE_DIST_pkey" PRIMARY KEY ("ZIPCODE_FROM", "ZIPCODE_TO");


--
-- Name: ZIPCODE_GEO_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY zipcode_geo
    ADD CONSTRAINT "ZIPCODE_GEO_pkey" PRIMARY KEY ("ZIPCODE");


--
-- Name: ZIP_CODES_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY zip_codes
    ADD CONSTRAINT "ZIP_CODES_pkey" PRIMARY KEY (zip);


--
-- Name: match_status_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY match_status
    ADD CONSTRAINT match_status_pkey PRIMARY KEY ("MatchStatusID");


--
-- Name: PROPOSED_MATCH_DriverID_fkey; Type: FK CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY proposed_match
    ADD CONSTRAINT "PROPOSED_MATCH_DriverID_fkey" FOREIGN KEY ("DriverID") REFERENCES driver("DriverID");


--
-- Name: PROPOSED_MATCH_RideID_fkey; Type: FK CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY proposed_match
    ADD CONSTRAINT "PROPOSED_MATCH_RideID_fkey" FOREIGN KEY ("RideID") REFERENCES requested_ride("RideID");


--
-- Name: PROPOSED_MATCH_RiderID_fkey; Type: FK CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY proposed_match
    ADD CONSTRAINT "PROPOSED_MATCH_RiderID_fkey" FOREIGN KEY ("RiderID") REFERENCES rider("RiderID");


--
-- Name: REQUESTED_RIDE_DriverID_fkey; Type: FK CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY requested_ride
    ADD CONSTRAINT "REQUESTED_RIDE_DriverID_fkey" FOREIGN KEY ("DriverID") REFERENCES driver("DriverID");


--
-- Name: REQUESTED_RIDE_RiderID_fkey; Type: FK CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY requested_ride
    ADD CONSTRAINT "REQUESTED_RIDE_RiderID_fkey" FOREIGN KEY ("RiderID") REFERENCES rider("RiderID");


--
-- Name: nov2016; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA nov2016 FROM PUBLIC;
REVOKE ALL ON SCHEMA nov2016 FROM postgres;
GRANT ALL ON SCHEMA nov2016 TO postgres;
GRANT USAGE ON SCHEMA nov2016 TO carpool_role;
GRANT ALL ON SCHEMA nov2016 TO carpool_admins;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: stage; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA stage FROM PUBLIC;
REVOKE ALL ON SCHEMA stage FROM postgres;
GRANT ALL ON SCHEMA stage TO postgres;
GRANT USAGE ON SCHEMA stage TO carpool_web_role;
GRANT ALL ON SCHEMA stage TO carpool_admins;


--
-- Name: cancel_ride_by_rider(integer, integer); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) FROM carpool_admins;
GRANT ALL ON FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) TO carpool_admins;
GRANT ALL ON FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) TO PUBLIC;
GRANT ALL ON FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) TO carpool_role;


--
-- Name: distance(double precision, double precision, double precision, double precision); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM PUBLIC;
REVOKE ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM carpool_admins;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_admins;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO PUBLIC;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_role;


--
-- Name: driver; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE driver FROM PUBLIC;
REVOKE ALL ON TABLE driver FROM carpool_admins;
GRANT ALL ON TABLE driver TO carpool_admins;
GRANT ALL ON TABLE driver TO carpool_role;


--
-- Name: DRIVER_DriverID_seq; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "DRIVER_DriverID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "DRIVER_DriverID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "DRIVER_DriverID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "DRIVER_DriverID_seq" TO carpool_role;


--
-- Name: proposed_match; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE proposed_match FROM PUBLIC;
REVOKE ALL ON TABLE proposed_match FROM carpool_admins;
GRANT ALL ON TABLE proposed_match TO carpool_admins;
GRANT ALL ON TABLE proposed_match TO carpool_role;


--
-- Name: PROPOSED_MATCH_ProposedMatchID_seq; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" TO carpool_role;


--
-- Name: requested_ride; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE requested_ride FROM PUBLIC;
REVOKE ALL ON TABLE requested_ride FROM carpool_admins;
GRANT ALL ON TABLE requested_ride TO carpool_admins;
GRANT ALL ON TABLE requested_ride TO carpool_role;


--
-- Name: REQUESTED_RIDE_RideID_seq; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" TO carpool_role;


--
-- Name: rider; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE rider FROM PUBLIC;
REVOKE ALL ON TABLE rider FROM carpool_admins;
GRANT ALL ON TABLE rider TO carpool_admins;
GRANT ALL ON TABLE rider TO carpool_role;


--
-- Name: RIDER_RiderID_seq; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "RIDER_RiderID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "RIDER_RiderID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "RIDER_RiderID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "RIDER_RiderID_seq" TO carpool_role;


--
-- Name: helper; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE helper FROM PUBLIC;
REVOKE ALL ON TABLE helper FROM carpool_admins;
GRANT ALL ON TABLE helper TO carpool_admins;
GRANT ALL ON TABLE helper TO carpool_role;


--
-- Name: match_status; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE match_status FROM PUBLIC;
REVOKE ALL ON TABLE match_status FROM carpool_admins;
GRANT ALL ON TABLE match_status TO carpool_admins;
GRANT ALL ON TABLE match_status TO carpool_role;


--
-- Name: match_status_MatchStatusID_seq; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "match_status_MatchStatusID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "match_status_MatchStatusID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "match_status_MatchStatusID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "match_status_MatchStatusID_seq" TO carpool_role;


--
-- Name: zip_codes; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE zip_codes FROM PUBLIC;
REVOKE ALL ON TABLE zip_codes FROM carpool_admins;
GRANT ALL ON TABLE zip_codes TO carpool_admins;
GRANT ALL ON TABLE zip_codes TO carpool_role;


--
-- Name: zipcode_dist; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE zipcode_dist FROM PUBLIC;
REVOKE ALL ON TABLE zipcode_dist FROM carpool_admins;
GRANT ALL ON TABLE zipcode_dist TO carpool_admins;
GRANT ALL ON TABLE zipcode_dist TO carpool_role;


--
-- Name: zipcode_geo; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE zipcode_geo FROM PUBLIC;
REVOKE ALL ON TABLE zipcode_geo FROM carpool_admins;
GRANT ALL ON TABLE zipcode_geo TO carpool_admins;
GRANT ALL ON TABLE zipcode_geo TO carpool_role;


SET search_path = stage, pg_catalog;

--
-- Name: websubmission_driver; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE websubmission_driver FROM PUBLIC;
REVOKE ALL ON TABLE websubmission_driver FROM carpool_admins;
GRANT ALL ON TABLE websubmission_driver TO carpool_admins;
GRANT INSERT ON TABLE websubmission_driver TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE websubmission_driver TO carpool_role;


--
-- Name: websubmission_rider; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE websubmission_rider FROM PUBLIC;
REVOKE ALL ON TABLE websubmission_rider FROM carpool_admins;
GRANT ALL ON TABLE websubmission_rider TO carpool_admins;
GRANT INSERT ON TABLE websubmission_rider TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE websubmission_rider TO carpool_role;


--
-- PostgreSQL database dump complete
--

