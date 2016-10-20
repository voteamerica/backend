-- actions by rider
--nov2016.rider_cancel_ride_request(UUID, phone number or lastname ?)
--nov2016.rider_cancel_confirmed_match(UUID_driver, UUID_rider, score, rider’s phone number or rider’s lastname ?)

-- actions by driver
--nov2016.driver_cancel_drive_offer(UUID, phone number or lastname ?)
--nov2016.driver_cancel_confirmed_match(UUID_driver, UUID_rider, driverr’s phone number or driver’s lastname ?)
--nov2016.driver_confirm_match(UUID_driver, UUID_rider, score, driver’s phone number or driver’s lastname ?)

-- functions return character varying with explanatory text of error condition. Empty string if success


-- Common function to update state of ride request record
CREATE OR REPLACE FUNCTION nov2016.update_ride_request_state(
    a_UUID character varying(50)	)
  RETURNS character varying AS
$BODY$
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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.update_ride_request_state(character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.update_ride_request_state(character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.update_ride_request_state(character varying) TO carpool_role;


-- Common function to update state of drive offer record
CREATE OR REPLACE FUNCTION nov2016.update_drive_offer_state(
    a_UUID character varying(50)	)
  RETURNS character varying AS
$BODY$
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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.update_drive_offer_state(character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.update_drive_offer_state(character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.update_drive_offer_state(character varying) TO carpool_role;


--------------------------------------------------------
-- USER STORY 003 - RIDER cancels ride request
--------------------------------------------------------
CREATE OR REPLACE FUNCTION nov2016.rider_cancel_ride_request(
    a_UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.rider_cancel_ride_request(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.rider_cancel_ride_request(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.rider_cancel_ride_request(character varying, character varying) TO carpool_role;



--------------------------------------------------------
-- USER STORY 004 - RIDER cancels a confirmed match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION nov2016.rider_cancel_confirmed_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
	a_score smallint,
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.rider_cancel_confirmed_match(character varying, character varying, smallint, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.rider_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.rider_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_role;

--------------------------------------------------------
-- USER STORY 013 - DRIVER cancels driver offer
--------------------------------------------------------
CREATE OR REPLACE FUNCTION nov2016.driver_cancel_drive_offer(
    a_UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.driver_cancel_drive_offer(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_cancel_drive_offer(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_cancel_drive_offer(character varying, character varying) TO carpool_role;

--------------------------------------------------------
-- USER STORY 014 - DRIVER cancels confirmed match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION nov2016.driver_cancel_confirmed_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
	a_score smallint,
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.driver_cancel_confirmed_match(character varying, character varying, smallint, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_role;

--------------------------------------------------------
-- USER STORY 015 - DRIVER confirms match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION nov2016.driver_confirm_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
	a_score smallint,
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.driver_confirm_match(character varying, character varying, smallint, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirm_match(character varying, character varying, smallint, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirm_match(character varying, character varying, smallint, character varying) TO carpool_role;
