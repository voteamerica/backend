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
-- Name: NOV2016; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "NOV2016";


ALTER SCHEMA "NOV2016" OWNER TO postgres;

--
-- Name: STAGE; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "STAGE";


ALTER SCHEMA "STAGE" OWNER TO postgres;

--
-- Name: SCHEMA "STAGE"; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA "STAGE" IS 'Staging Area';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = "NOV2016", pg_catalog;

--
-- Name: cancel_ride_by_rider(integer, integer); Type: FUNCTION; Schema: NOV2016; Owner: carpool_admins
--

CREATE FUNCTION cancel_ride_by_rider("RiderID" integer DEFAULT '-1'::integer, "RequestedRideID" integer DEFAULT '-1'::integer) RETURNS integer
    LANGUAGE sql
    AS $_$

UPDATE "NOV2016"."REQUESTED_RIDE"
   SET  "Active" = '0'::bit(1)
       ,"ModifiedTimestamp" = now() at time zone 'utc'
       ,"ModifiedBy" = 'CancelRider'
 WHERE "REQUESTED_RIDE"."RiderID" = $1
 ;
 
 SELECT 1;
 

$_$;


ALTER FUNCTION "NOV2016".cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) OWNER TO carpool_admins;

--
-- Name: FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer); Type: COMMENT; Schema: NOV2016; Owner: carpool_admins
--

COMMENT ON FUNCTION cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) IS 'Performs actions necessary to ensure that the appropriate parties know that the need for the scheduled ride has evaporated.';


--
-- Name: distance(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: NOV2016; Owner: carpool_admins
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


ALTER FUNCTION "NOV2016".distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) OWNER TO carpool_admins;

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

SET search_path = "NOV2016", pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: BORDERING_STATE; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "BORDERING_STATE" (
    stateabbrev1 character(2),
    stateabbrev2 character(2)
);


ALTER TABLE "BORDERING_STATE" OWNER TO carpool_admins;

--
-- Name: DRIVER; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "DRIVER" (
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


ALTER TABLE "DRIVER" OWNER TO carpool_admins;

--
-- Name: DRIVER_DriverID_seq; Type: SEQUENCE; Schema: NOV2016; Owner: carpool_admins
--

CREATE SEQUENCE "DRIVER_DriverID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "DRIVER_DriverID_seq" OWNER TO carpool_admins;

--
-- Name: DRIVER_DriverID_seq; Type: SEQUENCE OWNED BY; Schema: NOV2016; Owner: carpool_admins
--

ALTER SEQUENCE "DRIVER_DriverID_seq" OWNED BY "DRIVER"."DriverID";


--
-- Name: MATCH_STATUS; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "MATCH_STATUS" (
    "MatchStatusID" integer NOT NULL,
    "MatchStatusName" character varying(255) NOT NULL
);


ALTER TABLE "MATCH_STATUS" OWNER TO carpool_admins;

--
-- Name: MATCH_STATUS_MatchStatusID_seq; Type: SEQUENCE; Schema: NOV2016; Owner: carpool_admins
--

CREATE SEQUENCE "MATCH_STATUS_MatchStatusID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "MATCH_STATUS_MatchStatusID_seq" OWNER TO carpool_admins;

--
-- Name: MATCH_STATUS_MatchStatusID_seq; Type: SEQUENCE OWNED BY; Schema: NOV2016; Owner: carpool_admins
--

ALTER SEQUENCE "MATCH_STATUS_MatchStatusID_seq" OWNED BY "MATCH_STATUS"."MatchStatusID";


--
-- Name: PROPOSED_MATCH; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "PROPOSED_MATCH" (
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


ALTER TABLE "PROPOSED_MATCH" OWNER TO carpool_admins;

--
-- Name: PROPOSED_MATCH_ProposedMatchID_seq; Type: SEQUENCE; Schema: NOV2016; Owner: carpool_admins
--

CREATE SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "PROPOSED_MATCH_ProposedMatchID_seq" OWNER TO carpool_admins;

--
-- Name: PROPOSED_MATCH_ProposedMatchID_seq; Type: SEQUENCE OWNED BY; Schema: NOV2016; Owner: carpool_admins
--

ALTER SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" OWNED BY "PROPOSED_MATCH"."ProposedMatchID";


--
-- Name: REQUESTED_RIDE; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "REQUESTED_RIDE" (
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


ALTER TABLE "REQUESTED_RIDE" OWNER TO carpool_admins;

--
-- Name: REQUESTED_RIDE_RideID_seq; Type: SEQUENCE; Schema: NOV2016; Owner: carpool_admins
--

CREATE SEQUENCE "REQUESTED_RIDE_RideID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "REQUESTED_RIDE_RideID_seq" OWNER TO carpool_admins;

--
-- Name: REQUESTED_RIDE_RideID_seq; Type: SEQUENCE OWNED BY; Schema: NOV2016; Owner: carpool_admins
--

ALTER SEQUENCE "REQUESTED_RIDE_RideID_seq" OWNED BY "REQUESTED_RIDE"."RideID";


--
-- Name: RIDER; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "RIDER" (
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


ALTER TABLE "RIDER" OWNER TO carpool_admins;

--
-- Name: RIDER_RiderID_seq; Type: SEQUENCE; Schema: NOV2016; Owner: carpool_admins
--

CREATE SEQUENCE "RIDER_RiderID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "RIDER_RiderID_seq" OWNER TO carpool_admins;

--
-- Name: RIDER_RiderID_seq; Type: SEQUENCE OWNED BY; Schema: NOV2016; Owner: carpool_admins
--

ALTER SEQUENCE "RIDER_RiderID_seq" OWNED BY "RIDER"."RiderID";


--
-- Name: USSTATE; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "USSTATE" (
    stateabbrev character(2) NOT NULL,
    statename character varying(50)
);


ALTER TABLE "USSTATE" OWNER TO carpool_admins;

--
-- Name: ZIPCODE_DIST; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "ZIPCODE_DIST" (
    "ZIPCODE_FROM" character(5) NOT NULL,
    "ZIPCODE_TO" character(5) NOT NULL,
    "DISTANCE_IN_MILES" numeric(10,2) DEFAULT 999.00
);


ALTER TABLE "ZIPCODE_DIST" OWNER TO carpool_admins;

--
-- Name: ZIPCODE_GEO; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "ZIPCODE_GEO" (
    "ZIPCODE" character(5) NOT NULL,
    "CITY" character varying(255) NOT NULL,
    "STATE" character(2) NOT NULL,
    "GEO_LAT" double precision NOT NULL,
    "GET_LONG" double precision NOT NULL,
    "GEO_POINT" point
);


ALTER TABLE "ZIPCODE_GEO" OWNER TO carpool_admins;

--
-- Name: ZIP_CODES; Type: TABLE; Schema: NOV2016; Owner: carpool_admins
--

CREATE TABLE "ZIP_CODES" (
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


ALTER TABLE "ZIP_CODES" OWNER TO carpool_admins;

SET search_path = "STAGE", pg_catalog;

--
-- Name: WEBSUBMISSION_DRIVER; Type: TABLE; Schema: STAGE; Owner: carpool_admins
--

CREATE TABLE "WEBSUBMISSION_DRIVER" (
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


ALTER TABLE "WEBSUBMISSION_DRIVER" OWNER TO carpool_admins;

--
-- Name: WEBSUBMISSION_HELPER; Type: TABLE; Schema: STAGE; Owner: carpool_admins
--

CREATE TABLE "WEBSUBMISSION_HELPER" (
    "timestamp" timestamp without time zone NOT NULL
);


ALTER TABLE "WEBSUBMISSION_HELPER" OWNER TO carpool_admins;

--
-- Name: WEBSUBMISSION_RIDER; Type: TABLE; Schema: STAGE; Owner: carpool_admins
--

CREATE TABLE "WEBSUBMISSION_RIDER" (
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


ALTER TABLE "WEBSUBMISSION_RIDER" OWNER TO carpool_admins;

SET search_path = "NOV2016", pg_catalog;

--
-- Name: DriverID; Type: DEFAULT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "DRIVER" ALTER COLUMN "DriverID" SET DEFAULT nextval('"DRIVER_DriverID_seq"'::regclass);


--
-- Name: MatchStatusID; Type: DEFAULT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "MATCH_STATUS" ALTER COLUMN "MatchStatusID" SET DEFAULT nextval('"MATCH_STATUS_MatchStatusID_seq"'::regclass);


--
-- Name: ProposedMatchID; Type: DEFAULT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "PROPOSED_MATCH" ALTER COLUMN "ProposedMatchID" SET DEFAULT nextval('"PROPOSED_MATCH_ProposedMatchID_seq"'::regclass);


--
-- Name: RideID; Type: DEFAULT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "REQUESTED_RIDE" ALTER COLUMN "RideID" SET DEFAULT nextval('"REQUESTED_RIDE_RideID_seq"'::regclass);


--
-- Name: RiderID; Type: DEFAULT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "RIDER" ALTER COLUMN "RiderID" SET DEFAULT nextval('"RIDER_RiderID_seq"'::regclass);


--
-- Name: DRIVER_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "DRIVER"
    ADD CONSTRAINT "DRIVER_pkey" PRIMARY KEY ("DriverID");


--
-- Name: MATCH_STATUS_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "MATCH_STATUS"
    ADD CONSTRAINT "MATCH_STATUS_pkey" PRIMARY KEY ("MatchStatusID");


--
-- Name: PROPOSED_MATCH_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "PROPOSED_MATCH"
    ADD CONSTRAINT "PROPOSED_MATCH_pkey" PRIMARY KEY ("ProposedMatchID");


--
-- Name: REQUESTED_RIDE_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "REQUESTED_RIDE"
    ADD CONSTRAINT "REQUESTED_RIDE_pkey" PRIMARY KEY ("RideID");


--
-- Name: RIDER_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "RIDER"
    ADD CONSTRAINT "RIDER_pkey" PRIMARY KEY ("RiderID");


--
-- Name: USSTATE_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "USSTATE"
    ADD CONSTRAINT "USSTATE_pkey" PRIMARY KEY (stateabbrev);


--
-- Name: ZIPCODE_DIST_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "ZIPCODE_DIST"
    ADD CONSTRAINT "ZIPCODE_DIST_pkey" PRIMARY KEY ("ZIPCODE_FROM", "ZIPCODE_TO");


--
-- Name: ZIPCODE_GEO_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "ZIPCODE_GEO"
    ADD CONSTRAINT "ZIPCODE_GEO_pkey" PRIMARY KEY ("ZIPCODE");


--
-- Name: ZIP_CODES_pkey; Type: CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "ZIP_CODES"
    ADD CONSTRAINT "ZIP_CODES_pkey" PRIMARY KEY (zip);


--
-- Name: PROPOSED_MATCH_DriverID_fkey; Type: FK CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "PROPOSED_MATCH"
    ADD CONSTRAINT "PROPOSED_MATCH_DriverID_fkey" FOREIGN KEY ("DriverID") REFERENCES "DRIVER"("DriverID");


--
-- Name: PROPOSED_MATCH_RideID_fkey; Type: FK CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "PROPOSED_MATCH"
    ADD CONSTRAINT "PROPOSED_MATCH_RideID_fkey" FOREIGN KEY ("RideID") REFERENCES "REQUESTED_RIDE"("RideID");


--
-- Name: PROPOSED_MATCH_RiderID_fkey; Type: FK CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "PROPOSED_MATCH"
    ADD CONSTRAINT "PROPOSED_MATCH_RiderID_fkey" FOREIGN KEY ("RiderID") REFERENCES "RIDER"("RiderID");


--
-- Name: REQUESTED_RIDE_DriverID_fkey; Type: FK CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "REQUESTED_RIDE"
    ADD CONSTRAINT "REQUESTED_RIDE_DriverID_fkey" FOREIGN KEY ("DriverID") REFERENCES "DRIVER"("DriverID");


--
-- Name: REQUESTED_RIDE_RiderID_fkey; Type: FK CONSTRAINT; Schema: NOV2016; Owner: carpool_admins
--

ALTER TABLE ONLY "REQUESTED_RIDE"
    ADD CONSTRAINT "REQUESTED_RIDE_RiderID_fkey" FOREIGN KEY ("RiderID") REFERENCES "RIDER"("RiderID");


--
-- Name: NOV2016; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA "NOV2016" FROM PUBLIC;
REVOKE ALL ON SCHEMA "NOV2016" FROM postgres;
GRANT ALL ON SCHEMA "NOV2016" TO postgres;
GRANT USAGE ON SCHEMA "NOV2016" TO carpool_role;
GRANT ALL ON SCHEMA "NOV2016" TO carpool_admins;


--
-- Name: STAGE; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA "STAGE" FROM PUBLIC;
REVOKE ALL ON SCHEMA "STAGE" FROM postgres;
GRANT ALL ON SCHEMA "STAGE" TO postgres;
GRANT USAGE ON SCHEMA "STAGE" TO carpool_web_role;
GRANT ALL ON SCHEMA "STAGE" TO carpool_admins;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: DRIVER; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "DRIVER" FROM PUBLIC;
REVOKE ALL ON TABLE "DRIVER" FROM carpool_admins;
GRANT ALL ON TABLE "DRIVER" TO carpool_admins;
GRANT ALL ON TABLE "DRIVER" TO carpool_role;


--
-- Name: DRIVER_DriverID_seq; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "DRIVER_DriverID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "DRIVER_DriverID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "DRIVER_DriverID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "DRIVER_DriverID_seq" TO carpool_role;


--
-- Name: MATCH_STATUS; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "MATCH_STATUS" FROM PUBLIC;
REVOKE ALL ON TABLE "MATCH_STATUS" FROM carpool_admins;
GRANT ALL ON TABLE "MATCH_STATUS" TO carpool_admins;
GRANT ALL ON TABLE "MATCH_STATUS" TO carpool_role;


--
-- Name: MATCH_STATUS_MatchStatusID_seq; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "MATCH_STATUS_MatchStatusID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "MATCH_STATUS_MatchStatusID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "MATCH_STATUS_MatchStatusID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "MATCH_STATUS_MatchStatusID_seq" TO carpool_role;


--
-- Name: PROPOSED_MATCH; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "PROPOSED_MATCH" FROM PUBLIC;
REVOKE ALL ON TABLE "PROPOSED_MATCH" FROM carpool_admins;
GRANT ALL ON TABLE "PROPOSED_MATCH" TO carpool_admins;
GRANT ALL ON TABLE "PROPOSED_MATCH" TO carpool_role;


--
-- Name: PROPOSED_MATCH_ProposedMatchID_seq; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "PROPOSED_MATCH_ProposedMatchID_seq" TO carpool_role;


--
-- Name: REQUESTED_RIDE; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "REQUESTED_RIDE" FROM PUBLIC;
REVOKE ALL ON TABLE "REQUESTED_RIDE" FROM carpool_admins;
GRANT ALL ON TABLE "REQUESTED_RIDE" TO carpool_admins;
GRANT ALL ON TABLE "REQUESTED_RIDE" TO carpool_role;


--
-- Name: REQUESTED_RIDE_RideID_seq; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "REQUESTED_RIDE_RideID_seq" TO carpool_role;


--
-- Name: RIDER; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "RIDER" FROM PUBLIC;
REVOKE ALL ON TABLE "RIDER" FROM carpool_admins;
GRANT ALL ON TABLE "RIDER" TO carpool_admins;
GRANT ALL ON TABLE "RIDER" TO carpool_role;


--
-- Name: RIDER_RiderID_seq; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE "RIDER_RiderID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "RIDER_RiderID_seq" FROM carpool_admins;
GRANT ALL ON SEQUENCE "RIDER_RiderID_seq" TO carpool_admins;
GRANT ALL ON SEQUENCE "RIDER_RiderID_seq" TO carpool_role;


--
-- Name: ZIPCODE_DIST; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "ZIPCODE_DIST" FROM PUBLIC;
REVOKE ALL ON TABLE "ZIPCODE_DIST" FROM carpool_admins;
GRANT ALL ON TABLE "ZIPCODE_DIST" TO carpool_admins;
GRANT ALL ON TABLE "ZIPCODE_DIST" TO carpool_role;


--
-- Name: ZIPCODE_GEO; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "ZIPCODE_GEO" FROM PUBLIC;
REVOKE ALL ON TABLE "ZIPCODE_GEO" FROM carpool_admins;
GRANT ALL ON TABLE "ZIPCODE_GEO" TO carpool_admins;
GRANT ALL ON TABLE "ZIPCODE_GEO" TO carpool_role;


--
-- Name: ZIP_CODES; Type: ACL; Schema: NOV2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE "ZIP_CODES" FROM PUBLIC;
REVOKE ALL ON TABLE "ZIP_CODES" FROM carpool_admins;
GRANT ALL ON TABLE "ZIP_CODES" TO carpool_admins;
GRANT ALL ON TABLE "ZIP_CODES" TO carpool_role;


SET search_path = "STAGE", pg_catalog;

--
-- Name: WEBSUBMISSION_DRIVER; Type: ACL; Schema: STAGE; Owner: carpool_admins
--

REVOKE ALL ON TABLE "WEBSUBMISSION_DRIVER" FROM PUBLIC;
REVOKE ALL ON TABLE "WEBSUBMISSION_DRIVER" FROM carpool_admins;
GRANT ALL ON TABLE "WEBSUBMISSION_DRIVER" TO carpool_admins;
GRANT INSERT ON TABLE "WEBSUBMISSION_DRIVER" TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "WEBSUBMISSION_DRIVER" TO carpool_role;


--
-- Name: WEBSUBMISSION_RIDER; Type: ACL; Schema: STAGE; Owner: carpool_admins
--

REVOKE ALL ON TABLE "WEBSUBMISSION_RIDER" FROM PUBLIC;
REVOKE ALL ON TABLE "WEBSUBMISSION_RIDER" FROM carpool_admins;
GRANT ALL ON TABLE "WEBSUBMISSION_RIDER" TO carpool_admins;
GRANT INSERT ON TABLE "WEBSUBMISSION_RIDER" TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "WEBSUBMISSION_RIDER" TO carpool_role;


--
-- PostgreSQL database dump complete
--
