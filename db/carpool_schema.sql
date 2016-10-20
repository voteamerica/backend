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


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = nov2016, pg_catalog;

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

--
-- Name: driver_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
    ride_request_row stage.websubmission_rider%ROWTYPE;
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	match_row nov2016.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
BEGIN 
	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM nov2016.match m, stage.websubmission_driver r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.state = 'MatchConfirmed'   -- We can confirmed only a 
	AND m.uuid_driver = r."UUID"
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Confirmed Match found for those parameters.';
	END IF;

	BEGIN
		v_step := 'S0';
		UPDATE nov2016.match
		SET state='Canceled'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver
		AND score = a_score;
	
		v_step := 'S1';
		SELECT * INTO ride_request_row
		FROM stage.websubmission_rider
		WHERE "UUID" = a_UUID_rider;	
		
		v_step := 'S2';
		INSERT INTO nov2016.outgoing_email (recipient, subject, body)
		VALUES (ride_request_row."RiderEmail", 
		'Cancellation Notice', 
		'Confirmed match was canceled by driver: ' || a_UUID_driver || ', ' || a_UUID_rider);

		v_step := 'S3';
		v_return_text := nov2016.update_drive_offer_state(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
	
		v_step := 'S4';
		v_return_text := nov2016.update_ride_request_state(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
		
		return '';
	
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: driver_cancel_confirmed_match,' || v_step;
	END;

END  

$$;


ALTER FUNCTION nov2016.driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_cancel_drive_offer(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	ride_request_row stage.websubmission_rider%ROWTYPE;
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	match_row nov2016.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
BEGIN 


	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM stage.websubmission_driver r
	WHERE r."UUID" = a_UUID
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Drive Offer found for those parameters';
	END IF;

	BEGIN

		v_step := 'S1';
		FOR match_row IN SELECT * FROM nov2016.match
			WHERE uuid_driver = a_UUID
			AND state = 'MatchConfirmed'
		
		LOOP
		
			v_step := 'S2';
			SELECT * INTO ride_request_row
			FROM stage.websubmission_rider
			WHERE "UUID" = match_row.uuid_rider;	
		
			v_step := 'S3';
			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."DriverEmail", 
			'Cancellation Notice', 
			'Confirmed match was canceled by rider: ' || match_row.uuid_rider || ', ' || match_row.uuid_driver);

			v_step := 'S4';
			UPDATE nov2016.match
			SET state = 'Canceled'
			WHERE uuid_rider = match_row.uuid_rider
			AND uuid_driver = match_row.uuid_driver;
			
			v_step := 'S5';
			v_return_text := nov2016.update_ride_request_state(match_row.uuid_rider);
			IF  v_return_text != ''
			THEN
				v_step := v_step || ' ' || v_return_text;
				RAISE EXCEPTION '%', v_return_text;
			END IF;
		
		END LOOP;
		
		v_step := 'S6';
		UPDATE nov2016.match
		SET state = 'Canceled'
		WHERE uuid_driver = a_UUID;
		
		v_step := 'S7';
		-- Update Drive Offer to Canceled
		UPDATE stage.websubmission_driver
		SET state='Canceled'
		WHERE "UUID" = a_UUID;
		
		return '';
    	
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: driver_cancel_drive_offer,' || v_step;
	END;

END  

$$;


ALTER FUNCTION nov2016.driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_confirm_match(character varying, character varying, smallint, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
    ride_request_row stage.websubmission_rider%ROWTYPE;
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	match_row nov2016.match%ROWTYPE;
	v_step character varying(200); 
	v_return_text character varying(200);	
BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM nov2016.match m, stage.websubmission_driver r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.score = a_score
	AND m.state = 'MatchProposed'   -- We can confirmed only a 
	AND m.uuid_driver = r."UUID"
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Match can be confirmed with for those parameters';
	END IF;

	BEGIN
		v_step := 'S0';
		UPDATE nov2016.match
		SET state='MatchConfirmed'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver
		AND score = a_score;
	
		v_step := 'S1';
		SELECT * INTO ride_request_row
		FROM stage.websubmission_rider
		WHERE "UUID" = a_UUID_rider;	
		
		v_step := 'S2';
		INSERT INTO nov2016.outgoing_email (recipient, subject, body)
		VALUES (ride_request_row."RiderEmail", 
		'Confirmation Notice', 
		'Match was confirmed by driver: ' || a_UUID_driver || ', ' || a_UUID_rider);

		v_step := 'S3, ' || a_UUID_driver;
		v_return_text := nov2016.update_drive_offer_state(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
	
		v_step := 'S4';
		v_return_text := nov2016.update_ride_request_state(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
		
		return '';
	
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: driver_confirm_match,' || v_step;
	END;


    END  

$$;


ALTER FUNCTION nov2016.driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: fct_modified_column(); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION fct_modified_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_updated_ts = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION nov2016.fct_modified_column() OWNER TO carpool_admins;

--
-- Name: queue_email_notif(); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION queue_email_notif() RETURNS trigger
    LANGUAGE plpgsql
    AS $$                                                                                                                  
DECLARE                                                                                                                    
                                                                                                                           
 v_subject nov2016.outgoing_email.subject%TYPE;                                                                            
 v_body nov2016.outgoing_email.body%TYPE;                                                                                  
                                                                                                                           
BEGIN                                                                                                                      
                                                                                                                           
    -- triggered by submitting a drive offer form                                                                          
    IF TG_TABLE_NAME = 'websubmission_driver' and TG_TABLE_SCHEMA='stage'                                                  
    THEN                                                                                                                   
                                                                                                                           
        IF NEW."DriverEmail" IS NOT NULL                                                                                   
        THEN                                                                                                               
                                                                                                                           
            v_subject := 'Thank you for submitting a Drive Offer';                                                         
            v_body := 'Your reference is : ' || NEW."UUID"                                                                 
                    || '\n Please retain the this reference for future interaction with our system'                        
                    || '\n In order to manage this Driver Offer, and to accept '                                           
                    || 'a proposed ride request, please use this link : '                                                  
                    || '\n https://api.carpoolvote.com/v2.0/driver?UUID=' || NEW."UUID" || '&DriverPhone=' || NEW."DriverPhone";
                                                                                                                           
            INSERT INTO nov2016.outgoing_email (recipient, subject, body)                                             
            VALUES (NEW."DriverEmail", v_subject, v_body);                                                                 
        END IF;                                                                                                            
                                                                                                                           
    -- triggered by submitting a ride request form                                                                         
    ELSIF TG_TABLE_NAME = 'websubmission_rider' and TG_TABLE_SCHEMA='stage'                                                
    THEN                                                                                                                   
        IF NEW."RiderEmail" IS NOT NULL                                                                                    
        THEN                                                                                                               
                                                                                                                           
            v_subject := 'Thank you for submitting a Ride Request';                                                        
                                                                                                                           
            v_body := 'Your reference is : ' || NEW."UUID"                                                                 
                    || '\n Please retain the this reference for future interaction with our system'                        
                    || '\n In order to manage this Ride Request, '                                                         
                    || 'please use this link : '                                                                           
                    || '\n https://api.carpoolvote.com/v2.0/rider?UUID=' || NEW."UUID" || '&RiderPhone=' || NEW."RiderPhone";
                                                                                                                           
            INSERT INTO nov2016.outgoing_email (recipient, subject, body)                                             
            VALUES (NEW."RiderEmail", v_subject, v_body);                                                                  
        END IF;                                                                                                            
    END IF;                                                                                                                
                                                                                                                           
    RETURN NEW;                                                                                                            
END;    
$$;


ALTER FUNCTION nov2016.queue_email_notif() OWNER TO carpool_admins;

--
-- Name: rider_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	ride_request_row stage.websubmission_rider%ROWTYPE;
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	match_row nov2016.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM nov2016.match m, stage.websubmission_rider r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.score = a_score
	AND m.state = 'MatchConfirmed'   -- We can cancel only a Confirmed match
	AND m.uuid_rider = r."UUID"
	AND (LOWER(r."RiderLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."RiderPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Confirmed Match found for those parameters.';
	END IF;

	BEGIN
		v_step := 'S0';
		UPDATE nov2016.match
		SET state='Canceled'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver
		AND score = a_score;
	
		v_step := 'S1';
		SELECT * INTO drive_offer_row
		FROM stage.websubmission_driver
		WHERE "UUID" = a_UUID_driver;	
		
		v_step := 'S2';
		INSERT INTO nov2016.outgoing_email (recipient, subject, body)
		VALUES (drive_offer_row."DriverEmail", 
		'Cancellation Notice', 
		'Confirmed match was canceled by rider: ' || a_UUID_driver || ', ' || a_UUID_rider);

		v_step := 'S3';
		v_return_text := nov2016.update_drive_offer_state(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
	
		v_step := 'S4';
		v_return_text := nov2016.update_ride_request_state(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
		
		return '';
	
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: rider_cancel_confirmed_match,' || v_step;
	END;
	
END  

$$;


ALTER FUNCTION nov2016.rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_cancel_ride_request(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	ride_request_row stage.websubmission_rider%ROWTYPE;
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	match_row nov2016.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM stage.websubmission_rider r
	WHERE r."UUID" = a_UUID
	AND (LOWER(r."RiderLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."RiderPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Ride Request found for those parameters';
	END IF;

	
	BEGIN

		v_step := 'S1';
		FOR match_row IN SELECT * FROM nov2016.match
			WHERE uuid_rider = a_UUID
			AND state = 'MatchConfirmed'
		
		LOOP
		
			v_step := 'S2';
			SELECT * INTO drive_offer_row
			FROM stage.websubmission_driver
			WHERE "UUID" = match_row.uuid_driver;	
		
			v_step := 'S3';
			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (drive_offer_row."DriverEmail", 
			'Cancellation Notice', 
			'Confirmed match was canceled by rider: ' || match_row.uuid_driver || ', ' || match_row.uuid_rider);

			v_step := 'S4';
			UPDATE nov2016.match
			SET state = 'Canceled'
			WHERE uuid_rider = match_row.uuid_rider
			AND uuid_driver = match_row.uuid_driver;
			
			v_step := 'S5';
			v_return_text := nov2016.update_drive_offer_state(match_row.uuid_driver);
			IF  v_return_text != ''
			THEN
				v_step := v_step || ' ' || v_return_text;
				RAISE EXCEPTION '%', v_return_text;
			END IF;
		
		END LOOP;
		
		v_step := 'S6';
		UPDATE nov2016.match
		SET state = 'Canceled'
		WHERE uuid_rider = a_UUID;
		
		v_step := 'S7';
		-- Update Ride Request to Canceled
		UPDATE stage.websubmission_rider
		SET state='Canceled'
		WHERE "UUID" = a_UUID;
		
		return '';
    
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: rider_cancel_ride_request,' || v_step;
	END;
	
END  

$$;


ALTER FUNCTION nov2016.rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: update_drive_offer_state(character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION update_drive_offer_state(a_uuid character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_step character varying(200);
BEGIN	

	BEGIN
	v_step := 'S1';
	
	-- If there is at least one match in MatchConfirmed state -> MatchConfirmed
	IF EXISTS ( 
		SELECT 1
		FROM nov2016.match
		WHERE uuid_driver = a_UUID
		AND state='MatchConfirmed'
	)
	THEN	
		v_step := 'S2';
		UPDATE stage.websubmission_driver
		SET state='MatchConfirmed'
		WHERE "UUID" = a_UUID;
	ELSIF EXISTS (   -- If there is at least one match in MatchProposed or MatchConfirmed -> MatchProposed
		SELECT 1
		FROM nov2016.match
		WHERE uuid_driver = a_UUID
		AND state = 'MatchProposed'
	)
	THEN
		v_step := 'S3';
		UPDATE stage.websubmission_driver
		SET state='MatchProposed'
		WHERE "UUID" = a_UUID;
	
	ELSE               -- default, is Pending
		v_step := 'S4';
		UPDATE stage.websubmission_driver
		SET state='Pending'
		WHERE "UUID" = a_UUID;
		
	END IF;
		
	RETURN '';
	
	EXCEPTION WHEN OTHERS
	THEN
		RAISE NOTICE 'Exception occurred during processing: update_drive_offer_state,%', v_step;
		return 'Exception occurred during processing: update_drive_offer_state,' || v_step;
	END;
			
END  

$$;


ALTER FUNCTION nov2016.update_drive_offer_state(a_uuid character varying) OWNER TO carpool_admins;

--
-- Name: update_ride_request_state(character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION update_ride_request_state(a_uuid character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_step character varying(200);
BEGIN	

	BEGIN
	v_step := 'S1';
	
	-- If there is at least one match in MatchConfirmed state -> MatchConfirmed
	IF EXISTS ( 
		SELECT 1
		FROM nov2016.match
		WHERE uuid_rider = a_UUID
		AND state='MatchConfirmed'
	)
	THEN	
		v_step := 'S2';
		UPDATE stage.websubmission_rider
		SET state='MatchConfirmed'
		WHERE "UUID" = a_UUID;
	ELSIF EXISTS (   -- If there is at least one match in MatchProposed or MatchConfirmed -> MatchProposed
		SELECT 1
		FROM nov2016.match
		WHERE uuid_rider = a_UUID
		AND state = 'MatchProposed'
	)
	THEN
		v_step := 'S3';
		UPDATE stage.websubmission_rider
		SET state='MatchProposed'
		WHERE "UUID" = a_UUID;
	
	ELSE               -- default, is Pending
		v_step := 'S4';
		UPDATE stage.websubmission_rider
		SET state='Pending'
		WHERE "UUID" = a_UUID;
		
	END IF;
		
	RETURN '';
	
	EXCEPTION WHEN OTHERS
	THEN
		RAISE NOTICE 'Exception occurred during processing: update_ride_request_state,%', v_step;
		return 'Exception occurred during processing: update_ride_request_state,' || v_step;
	END;
			
END  

$$;


ALTER FUNCTION nov2016.update_ride_request_state(a_uuid character varying) OWNER TO carpool_admins;

--
-- Name: zip_distance(integer, integer); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION zip_distance(zip_from integer, zip_to integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $$

DECLARE 
zip_from_row nov2016.zip_codes%ROWTYPE;
zip_to_row   nov2016.zip_codes%ROWTYPE;
BEGIN
    SELECT * INTO zip_from_row FROM nov2016.zip_codes WHERE zip=zip_from::character varying;
    SELECT * INTO zip_to_row   FROM nov2016.zip_codes WHERE zip=zip_to::character varying;
    RETURN nov2016.distance(
                        zip_from_row.latitude_numeric,
                        zip_from_row.longitude_numeric,
                        zip_to_row.latitude_numeric,
                        zip_to_row.longitude_numeric);
END  

$$;


ALTER FUNCTION nov2016.zip_distance(zip_from integer, zip_to integer) OWNER TO carpool_admins;

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

SET search_path = stage, pg_catalog;

--
-- Name: create_riders(); Type: FUNCTION; Schema: stage; Owner: carpool_admins
--

CREATE FUNCTION create_riders() RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
DECLARE
   tstamp timestamp := '2000-01-01';
BEGIN
   RAISE NOTICE 'tstamp here is %', tstamp; 
    -- get timestamp of unprocessed riders 
    IF EXISTS (select 1 from stage.status_rider) THEN
      select MAX("CreatedTimeStamp") into tstamp from stage.status_rider;
    ELSE 
      tstamp := '2010-01-01';
    END IF;

    -- create intermediate table of timestamps, processed flag and driverId
    INSERT INTO 
      stage.status_rider ("CreatedTimeStamp")     
    SELECT 
      "CreatedTimeStamp" FROM stage.websubmission_rider 
    WHERE 
      "CreatedTimeStamp" > tstamp;

    -- create riders in nov2016 db
    -- only insert riders in intermediate tables, and with status == 1
    -- ?? timestamp to be creation of nov2016 row, or original submission ??
    INSERT INTO 
      nov2016.rider 
        (
        "RiderID", "Name", "Phone", "Email", "EmailValidated",
        "State", "City", "Notes", "DataEntryPoint", "VulnerablePopulation",
        "NeedsWheelChair", "Active"
        )     
    SELECT
      stage.status_rider."RiderID",
      concat_ws(' ', 
                stage.websubmission_rider."RiderFirstName"::text, 
                stage.websubmission_rider."RiderLastName"::text) 
      ,
      stage.websubmission_rider."RiderPhone",
      stage.websubmission_rider."RiderEmail",
      stage.websubmission_rider."RiderEmailValidated"::int::bit,

      stage.websubmission_rider."RiderVotingState",
      'city?',
      'notes?',
      'entry?',
      stage.websubmission_rider."RiderIsVulnerable"::int::bit,

      stage.websubmission_rider."WheelchairCount"::bit,
      true::int::bit
    FROM 
      stage.websubmission_rider
    INNER JOIN 
      stage.status_rider 
    ON 
      (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
    WHERE 
          stage.websubmission_rider."CreatedTimeStamp" > tstamp 
      AND stage.status_rider.status = 1;
    
    UPDATE 
      stage.status_rider
    SET
      status = 100
    WHERE
          stage.status_rider."CreatedTimeStamp" > tstamp 
      AND stage.status_rider.status = 1;

    -- RAISE EXCEPTION 'Nonexistent ID --> %', user_id
    --   USING HINT = 'Please check your user ID';

    RETURN tstamp;
END;
$$;


ALTER FUNCTION stage.create_riders() OWNER TO carpool_admins;

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
-- Name: match; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE match (
    state character varying(30) DEFAULT 'Proposed'::character varying NOT NULL,
    uuid_driver character varying(50) NOT NULL,
    uuid_rider character varying(50) NOT NULL,
    score smallint DEFAULT 0 NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE match OWNER TO carpool_admins;

--
-- Name: COLUMN match.state; Type: COMMENT; Schema: nov2016; Owner: carpool_admins
--

COMMENT ON COLUMN match.state IS '- MatchProposed
- MatchConfirmed
- Rejected,
- Canceled
- Rejected
- Expired';


--
-- Name: match_engine_activity_log; Type: TABLE; Schema: nov2016; Owner: carpool_admins
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
-- Name: match_engine_scheduler; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE match_engine_scheduler (
    need_run_flag boolean
);


ALTER TABLE match_engine_scheduler OWNER TO carpool_admins;

--
-- Name: COLUMN match_engine_scheduler.need_run_flag; Type: COMMENT; Schema: nov2016; Owner: carpool_admins
--

COMMENT ON COLUMN match_engine_scheduler.need_run_flag IS 'the matching engine will process records only when need_run_flag is True
The matching engine resets the flag at the end of its execution';


--
-- Name: outgoing_email; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE outgoing_email (
    id integer NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    state character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    recipient character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    body text NOT NULL,
    emission_info text
);


ALTER TABLE outgoing_email OWNER TO carpool_admins;

--
-- Name: outgoing_email_id_seq; Type: SEQUENCE; Schema: nov2016; Owner: carpool_admins
--

CREATE SEQUENCE outgoing_email_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE outgoing_email_id_seq OWNER TO carpool_admins;

--
-- Name: outgoing_email_id_seq; Type: SEQUENCE OWNED BY; Schema: nov2016; Owner: carpool_admins
--

ALTER SEQUENCE outgoing_email_id_seq OWNED BY outgoing_email.id;


--
-- Name: outgoing_sms; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE outgoing_sms (
    id integer NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    state character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    recipient character varying(15) NOT NULL,
    body text NOT NULL,
    emission_info text
);


ALTER TABLE outgoing_sms OWNER TO carpool_admins;

--
-- Name: outgoing_sms_id_seq; Type: SEQUENCE; Schema: nov2016; Owner: carpool_admins
--

CREATE SEQUENCE outgoing_sms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE outgoing_sms_id_seq OWNER TO carpool_admins;

--
-- Name: outgoing_sms_id_seq; Type: SEQUENCE OWNED BY; Schema: nov2016; Owner: carpool_admins
--

ALTER SEQUENCE outgoing_sms_id_seq OWNED BY outgoing_sms.id;


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

SET search_path = stage, pg_catalog;

--
-- Name: status_rider; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE status_rider (
    "RiderID" integer DEFAULT nextval('nov2016."RIDER_RiderID_seq"'::regclass) NOT NULL,
    status integer DEFAULT 1 NOT NULL,
    "CreatedTimeStamp" timestamp without time zone NOT NULL
);


ALTER TABLE status_rider OWNER TO carpool_admins;

--
-- Name: sweep_status; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE sweep_status (
    id integer NOT NULL,
    status character varying(50)
);


ALTER TABLE sweep_status OWNER TO carpool_admins;

--
-- Name: websubmission_driver; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_driver (
    "UUID" character varying(50) DEFAULT public.gen_random_uuid() NOT NULL,
    "IPAddress" character varying(20),
    "DriverCollectionZIP" character varying(5) NOT NULL,
    "DriverCollectionRadius" integer NOT NULL,
    "AvailableDriveTimesJSON" character varying(2000),
    "DriverCanLoadRiderWithWheelchair" boolean DEFAULT false NOT NULL,
    "SeatCount" integer DEFAULT 1,
    "DriverLicenseNumber" character varying(50),
    "DriverFirstName" character varying(255) NOT NULL,
    "DriverLastName" character varying(255) NOT NULL,
    "PermissionCanRunBackgroundCheck" boolean DEFAULT false NOT NULL,
    "DriverEmail" character varying(255),
    "DriverPhone" character varying(20),
    "DrivingOnBehalfOfOrganization" boolean DEFAULT false NOT NULL,
    "DrivingOBOOrganizationName" character varying(255),
    "RidersCanSeeDriverDetails" boolean DEFAULT false NOT NULL,
    "DriverWillNotTalkPolitics" boolean DEFAULT false NOT NULL,
    "ReadyToMatch" boolean DEFAULT false NOT NULL,
    "PleaseStayInTouch" boolean DEFAULT false NOT NULL,
    state character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    state_info text,
    "DriverPreferredContactMethod" character varying(50)
);


ALTER TABLE websubmission_driver OWNER TO carpool_admins;

--
-- Name: vw_drive_offer; Type: VIEW; Schema: stage; Owner: carpool_admins
--

CREATE VIEW vw_drive_offer AS
 SELECT websubmission_driver."UUID",
    websubmission_driver."DriverLastName",
    websubmission_driver."DriverPhone",
    websubmission_driver.state,
    websubmission_driver.created_ts,
    websubmission_driver.last_updated_ts,
    websubmission_driver."DriverCollectionZIP",
    websubmission_driver."DriverCollectionRadius",
    websubmission_driver."DriverCanLoadRiderWithWheelchair",
    websubmission_driver."SeatCount",
    websubmission_driver."DrivingOnBehalfOfOrganization",
    websubmission_driver."AvailableDriveTimesJSON"
   FROM websubmission_driver;


ALTER TABLE vw_drive_offer OWNER TO carpool_admins;

--
-- Name: websubmission_rider; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_rider (
    "UUID" character varying(50) DEFAULT public.gen_random_uuid() NOT NULL,
    "IPAddress" character varying(20),
    "RiderFirstName" character varying(255) NOT NULL,
    "RiderLastName" character varying(255) NOT NULL,
    "RiderEmail" character varying(255),
    "RiderPhone" character varying(20),
    "RiderVotingState" character(2),
    "RiderCollectionZIP" character varying(5) NOT NULL,
    "RiderDropOffZIP" character varying(5) NOT NULL,
    "AvailableRideTimesJSON" character varying(2000),
    "TotalPartySize" integer,
    "TwoWayTripNeeded" boolean DEFAULT false NOT NULL,
    "RiderIsVulnerable" boolean DEFAULT false NOT NULL,
    "RiderWillNotTalkPolitics" boolean DEFAULT false NOT NULL,
    "PleaseStayInTouch" boolean DEFAULT false NOT NULL,
    "NeedWheelchair" boolean DEFAULT false NOT NULL,
    "RiderPreferredContactMethod" character varying(50),
    "RiderAccommodationNotes" character varying(1000),
    "RiderLegalConsent" boolean,
    "ReadyToMatch" boolean,
    state character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    state_info text
);


ALTER TABLE websubmission_rider OWNER TO carpool_admins;

--
-- Name: vw_ride_request; Type: VIEW; Schema: stage; Owner: carpool_admins
--

CREATE VIEW vw_ride_request AS
 SELECT websubmission_rider."UUID" AS uuid,
    websubmission_rider."RiderLastName",
    websubmission_rider."RiderPhone",
    websubmission_rider.state,
    websubmission_rider.created_ts,
    websubmission_rider.last_updated_ts,
    websubmission_rider."RiderCollectionZIP",
    websubmission_rider."RiderDropOffZIP",
    websubmission_rider."TotalPartySize",
    websubmission_rider."RiderIsVulnerable",
    websubmission_rider."NeedWheelchair",
    websubmission_rider."AvailableRideTimesJSON"
   FROM websubmission_rider;


ALTER TABLE vw_ride_request OWNER TO carpool_admins;

--
-- Name: vw_unmatched_riders; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE vw_unmatched_riders (
    count bigint,
    zip character varying(5),
    state character(2),
    latitude character varying(10),
    longitude character varying(10),
    city character varying(50),
    full_state character varying(50),
    latitude_numeric real,
    longitude_numeric real,
    latlong point
);

ALTER TABLE ONLY vw_unmatched_riders REPLICA IDENTITY NOTHING;


ALTER TABLE vw_unmatched_riders OWNER TO carpool_admins;

--
-- Name: websubmission_helper; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_helper (
    "timestamp" timestamp without time zone NOT NULL,
    helpername character varying(100) NOT NULL,
    helperemail character varying(250) NOT NULL,
    helpercapability character varying(500)[],
    sweep_status_id integer DEFAULT '-1'::integer NOT NULL,
    "UUID" character varying(50) DEFAULT public.gen_random_uuid() NOT NULL
);


ALTER TABLE websubmission_helper OWNER TO carpool_admins;

SET search_path = nov2016, pg_catalog;

--
-- Name: DriverID; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY driver ALTER COLUMN "DriverID" SET DEFAULT nextval('"DRIVER_DriverID_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_email ALTER COLUMN id SET DEFAULT nextval('outgoing_email_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_sms ALTER COLUMN id SET DEFAULT nextval('outgoing_sms_id_seq'::regclass);


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
-- Name: ZIP_CODES_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY zip_codes
    ADD CONSTRAINT "ZIP_CODES_pkey" PRIMARY KEY (zip);


--
-- Name: match_engine_activity_pk; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY match_engine_activity_log
    ADD CONSTRAINT match_engine_activity_pk PRIMARY KEY (start_ts);


--
-- Name: match_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY match
    ADD CONSTRAINT match_pkey PRIMARY KEY (uuid_driver, uuid_rider, score);


--
-- Name: outgoing_email_pk; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_email
    ADD CONSTRAINT outgoing_email_pk PRIMARY KEY (id);


--
-- Name: outgoing_sms_pk; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY outgoing_sms
    ADD CONSTRAINT outgoing_sms_pk PRIMARY KEY (id);


SET search_path = stage, pg_catalog;

--
-- Name: driver_pk; Type: CONSTRAINT; Schema: stage; Owner: carpool_admins
--

ALTER TABLE ONLY websubmission_driver
    ADD CONSTRAINT driver_pk PRIMARY KEY ("UUID");


--
-- Name: helper_pk; Type: CONSTRAINT; Schema: stage; Owner: carpool_admins
--

ALTER TABLE ONLY websubmission_helper
    ADD CONSTRAINT helper_pk PRIMARY KEY ("UUID");


--
-- Name: rider_pk; Type: CONSTRAINT; Schema: stage; Owner: carpool_admins
--

ALTER TABLE ONLY websubmission_rider
    ADD CONSTRAINT rider_pk PRIMARY KEY ("UUID");


--
-- Name: sweep_status_pkey; Type: CONSTRAINT; Schema: stage; Owner: carpool_admins
--

ALTER TABLE ONLY sweep_status
    ADD CONSTRAINT sweep_status_pkey PRIMARY KEY (id);


--
-- Name: _RETURN; Type: RULE; Schema: stage; Owner: carpool_admins
--

CREATE RULE "_RETURN" AS
    ON SELECT TO vw_unmatched_riders DO INSTEAD  SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.latitude,
    zip_codes.longitude,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric,
    zip_codes.latlong
   FROM websubmission_rider rider,
    nov2016.zip_codes zip_codes
  WHERE (((rider.state)::text = ANY ((ARRAY['Pending'::character varying, 'MatchProposed'::character varying])::text[])) AND ((rider."RiderCollectionZIP")::text = (zip_codes.zip)::text))
  GROUP BY zip_codes.zip;


SET search_path = nov2016, pg_catalog;

--
-- Name: trg_update_match; Type: TRIGGER; Schema: nov2016; Owner: carpool_admins
--

CREATE TRIGGER trg_update_match BEFORE UPDATE OF state ON match FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


--
-- Name: trg_update_outgoing_email; Type: TRIGGER; Schema: nov2016; Owner: carpool_admins
--

CREATE TRIGGER trg_update_outgoing_email BEFORE UPDATE OF state ON outgoing_email FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


--
-- Name: trg_update_outgoing_sms; Type: TRIGGER; Schema: nov2016; Owner: carpool_admins
--

CREATE TRIGGER trg_update_outgoing_sms BEFORE UPDATE OF state ON outgoing_sms FOR EACH ROW EXECUTE PROCEDURE fct_modified_column();


SET search_path = stage, pg_catalog;

--
-- Name: send_email_notif_ins_driver_trg; Type: TRIGGER; Schema: stage; Owner: carpool_admins
--

CREATE TRIGGER send_email_notif_ins_driver_trg AFTER INSERT ON websubmission_driver FOR EACH ROW EXECUTE PROCEDURE nov2016.queue_email_notif();


--
-- Name: send_email_notif_ins_rider_trg; Type: TRIGGER; Schema: stage; Owner: carpool_admins
--

CREATE TRIGGER send_email_notif_ins_rider_trg AFTER INSERT ON websubmission_rider FOR EACH ROW EXECUTE PROCEDURE nov2016.queue_email_notif();


--
-- Name: trg_update_websub_driver; Type: TRIGGER; Schema: stage; Owner: carpool_admins
--

CREATE TRIGGER trg_update_websub_driver BEFORE UPDATE OF state ON websubmission_driver FOR EACH ROW EXECUTE PROCEDURE nov2016.fct_modified_column();


--
-- Name: trg_update_websub_rider; Type: TRIGGER; Schema: stage; Owner: carpool_admins
--

CREATE TRIGGER trg_update_websub_rider BEFORE UPDATE OF state ON websubmission_rider FOR EACH ROW EXECUTE PROCEDURE nov2016.fct_modified_column();


SET search_path = nov2016, pg_catalog;

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
GRANT USAGE ON SCHEMA nov2016 TO carpool_web_role;


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
-- Name: distance(double precision, double precision, double precision, double precision); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM PUBLIC;
REVOKE ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM carpool_admins;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_admins;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO PUBLIC;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_role;


--
-- Name: driver_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_cancel_drive_offer(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_confirm_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;


--
-- Name: fct_modified_column(); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION fct_modified_column() FROM PUBLIC;
REVOKE ALL ON FUNCTION fct_modified_column() FROM carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_role;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_web_role;


--
-- Name: rider_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_cancel_ride_request(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: update_drive_offer_state(character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION update_drive_offer_state(a_uuid character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_drive_offer_state(a_uuid character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION update_drive_offer_state(a_uuid character varying) TO carpool_admins;
GRANT ALL ON FUNCTION update_drive_offer_state(a_uuid character varying) TO PUBLIC;
GRANT ALL ON FUNCTION update_drive_offer_state(a_uuid character varying) TO carpool_web;
GRANT ALL ON FUNCTION update_drive_offer_state(a_uuid character varying) TO carpool_role;


--
-- Name: update_ride_request_state(character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION update_ride_request_state(a_uuid character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_ride_request_state(a_uuid character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION update_ride_request_state(a_uuid character varying) TO carpool_admins;
GRANT ALL ON FUNCTION update_ride_request_state(a_uuid character varying) TO PUBLIC;
GRANT ALL ON FUNCTION update_ride_request_state(a_uuid character varying) TO carpool_web;
GRANT ALL ON FUNCTION update_ride_request_state(a_uuid character varying) TO carpool_role;


--
-- Name: zip_distance(integer, integer); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION zip_distance(zip_from integer, zip_to integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION zip_distance(zip_from integer, zip_to integer) FROM carpool_admins;
GRANT ALL ON FUNCTION zip_distance(zip_from integer, zip_to integer) TO carpool_admins;
GRANT ALL ON FUNCTION zip_distance(zip_from integer, zip_to integer) TO PUBLIC;
GRANT ALL ON FUNCTION zip_distance(zip_from integer, zip_to integer) TO carpool_role;
GRANT ALL ON FUNCTION zip_distance(zip_from integer, zip_to integer) TO carpool_web_role;


SET search_path = stage, pg_catalog;

--
-- Name: create_riders(); Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION create_riders() FROM PUBLIC;
REVOKE ALL ON FUNCTION create_riders() FROM carpool_admins;
GRANT ALL ON FUNCTION create_riders() TO carpool_admins;
GRANT ALL ON FUNCTION create_riders() TO carpool_role;


SET search_path = nov2016, pg_catalog;

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
-- Name: match; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE match FROM PUBLIC;
REVOKE ALL ON TABLE match FROM carpool_admins;
GRANT ALL ON TABLE match TO carpool_admins;
GRANT ALL ON TABLE match TO carpool_role;
GRANT SELECT,UPDATE ON TABLE match TO carpool_web_role;


--
-- Name: match_engine_activity_log; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE match_engine_activity_log FROM PUBLIC;
REVOKE ALL ON TABLE match_engine_activity_log FROM carpool_admins;
GRANT ALL ON TABLE match_engine_activity_log TO carpool_admins;
GRANT INSERT ON TABLE match_engine_activity_log TO carpool_role;
GRANT SELECT ON TABLE match_engine_activity_log TO carpool_web_role;


--
-- Name: match_engine_scheduler; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE match_engine_scheduler FROM PUBLIC;
REVOKE ALL ON TABLE match_engine_scheduler FROM carpool_admins;
GRANT ALL ON TABLE match_engine_scheduler TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE match_engine_scheduler TO carpool_role;
GRANT UPDATE ON TABLE match_engine_scheduler TO carpool_web_role;


--
-- Name: outgoing_email; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE outgoing_email FROM PUBLIC;
REVOKE ALL ON TABLE outgoing_email FROM carpool_admins;
GRANT ALL ON TABLE outgoing_email TO carpool_admins;
GRANT ALL ON TABLE outgoing_email TO carpool_role;
GRANT INSERT ON TABLE outgoing_email TO carpool_web;


--
-- Name: outgoing_email_id_seq; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE outgoing_email_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE outgoing_email_id_seq FROM carpool_admins;
GRANT ALL ON SEQUENCE outgoing_email_id_seq TO carpool_admins;
GRANT SELECT,USAGE ON SEQUENCE outgoing_email_id_seq TO carpool_web;


--
-- Name: outgoing_sms; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE outgoing_sms FROM PUBLIC;
REVOKE ALL ON TABLE outgoing_sms FROM carpool_admins;
GRANT ALL ON TABLE outgoing_sms TO carpool_admins;
GRANT ALL ON TABLE outgoing_sms TO carpool_role;
GRANT INSERT ON TABLE outgoing_sms TO carpool_web;


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


SET search_path = stage, pg_catalog;

--
-- Name: status_rider; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE status_rider FROM PUBLIC;
REVOKE ALL ON TABLE status_rider FROM carpool_admins;
GRANT ALL ON TABLE status_rider TO carpool_admins;
GRANT ALL ON TABLE status_rider TO carpool_role;


--
-- Name: sweep_status; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE sweep_status FROM PUBLIC;
REVOKE ALL ON TABLE sweep_status FROM carpool_admins;
GRANT ALL ON TABLE sweep_status TO carpool_admins;
GRANT ALL ON TABLE sweep_status TO carpool_role;


--
-- Name: websubmission_driver; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE websubmission_driver FROM PUBLIC;
REVOKE ALL ON TABLE websubmission_driver FROM carpool_admins;
GRANT ALL ON TABLE websubmission_driver TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE websubmission_driver TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE websubmission_driver TO carpool_role;


--
-- Name: websubmission_driver.UUID; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL("UUID") ON TABLE websubmission_driver FROM PUBLIC;
REVOKE ALL("UUID") ON TABLE websubmission_driver FROM carpool_admins;
GRANT SELECT("UUID") ON TABLE websubmission_driver TO carpool_web;


--
-- Name: vw_drive_offer; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_drive_offer FROM PUBLIC;
REVOKE ALL ON TABLE vw_drive_offer FROM carpool_admins;
GRANT ALL ON TABLE vw_drive_offer TO carpool_admins;
GRANT SELECT ON TABLE vw_drive_offer TO carpool_role;


--
-- Name: websubmission_rider; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE websubmission_rider FROM PUBLIC;
REVOKE ALL ON TABLE websubmission_rider FROM carpool_admins;
GRANT ALL ON TABLE websubmission_rider TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE websubmission_rider TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE websubmission_rider TO carpool_role;


--
-- Name: websubmission_rider.UUID; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL("UUID") ON TABLE websubmission_rider FROM PUBLIC;
REVOKE ALL("UUID") ON TABLE websubmission_rider FROM carpool_admins;
GRANT SELECT("UUID") ON TABLE websubmission_rider TO carpool_web;


--
-- Name: vw_ride_request; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_ride_request FROM PUBLIC;
REVOKE ALL ON TABLE vw_ride_request FROM carpool_admins;
GRANT ALL ON TABLE vw_ride_request TO carpool_admins;
GRANT SELECT ON TABLE vw_ride_request TO carpool_role;


--
-- Name: vw_unmatched_riders; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_riders FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_riders FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_riders TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_riders TO carpool_web_role;
GRANT SELECT ON TABLE vw_unmatched_riders TO carpool_role;


--
-- Name: websubmission_helper; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE websubmission_helper FROM PUBLIC;
REVOKE ALL ON TABLE websubmission_helper FROM carpool_admins;
GRANT ALL ON TABLE websubmission_helper TO carpool_admins;
GRANT INSERT ON TABLE websubmission_helper TO carpool_web_role;
GRANT ALL ON TABLE websubmission_helper TO carpool_role;


--
-- PostgreSQL database dump complete
--

