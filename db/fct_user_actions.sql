-- actions by rider
--nov2016.cancel_ride_request(UUID, phone number or lastname ?)
--nov2016.rider_cancel_confirmed_match(UUID_driver, UUID_rider, rider’s phone number or rider’s lastname ?)

-- actions by driver
--nov2016.cancel_drive_offer(UUID, phone number or lastname ?)
--nov2016.driver_cancel_confirmed_match(UUID_driver, UUID_rider, driverr’s phone number or driver’s lastname ?)
--nov2016.confirm_match(UUID_driver, UUID_rider, driver’s phone number or driver’s lastname ?)

-- Return code of 0 is used for success. Return code 1 for input validation error.  Return code 2 for execution error after validation succeeded.

CREATE OR REPLACE FUNCTION nov2016.cancel_ride_request(
    UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

DECLARE                                                   
	ride_request_row stage.websubmission_rider%ROWTYPE;
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	match_row nov2016.match%ROWTYPE;
	v_step character varying(200);
BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM stage.websubmission_rider r
	WHERE r."UUID" = UUID
	AND (LOWER(r."RiderLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."RiderPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Ride Request found for those parameters';
	END IF;

	
	BEGIN
		v_step := 'S0';
		SELECT * INTO ride_request_row
		FROM stage.websubmission_rider
		WHERE "UUID" = UUID;
		
		IF ride_request_row.state = 'MatchConfirmed'
		THEN
			v_step := 'S1';
			-- Get the UUID of the confirmed match driver
			SELECT * INTO match_row
			FROM nov2016.match
			WHERE uuid_rider = UUID
			AND stage = 'MatchConfirmed';
		
			v_step := 'S2';
			SELECT * INTO drive_offer_row
			FROM stage.websubmission_driver
			WHERE "UUID" = match_row.uuid_driver;	
		
			v_step := 'S3';
			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (drive_offer_row."DriverEmail", 
			"Cancellation Notice", 
			"Confirmed match was canceled by rider: " || match_row.uuid_driver || ', ' || match_row.uuid_rider);

			v_step := 'S4';
			-- If this drive offer has no other confirmed matches, downgrade to MatchProposed
			IF NOT EXISTS ( 
			SELECT 1
			FROM nov2016.match
			WHERE uuid_driver = drive_offer_row."UUID"
			AND state='MatchConfirmed'
			)
			THEN
			
				v_step := 'S5';
				UPDATE stage.websubmission_driver
				SET stage='MatchProposed'
				WHERE "UUID" = match_row.uuid_driver;
			
			END IF;
			
			v_step := 'S6';
			-- If there are really no other match for this driver, downgrade to Pending
			IF NOT EXISTS ( 
			SELECT 1
			FROM nov2016.match
			WHERE uuid_driver = drive_offer_row."UUID"
			)
			THEN
			
				v_step := 'S7';
				UPDATE stage.websubmission_driver
				SET stage='Pending'
				WHERE "UUID" = match_row.uuid_driver;
			
			END IF;
			
			
		END IF;

		v_step := 'S8';
		-- Update all matched for this Ride Offer to Canceled
		UPDATE nov2016.match SET state='Canceled'
		WHERE uuid_rider=UUID;
		
		v_step := 'S9';
		-- Update Ride Offer to Canceled
		UPDATE stage.websubmission_rider
		SET state='Canceled'
		WHERE "UUID" = UUID;
		
		return '';
    
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: ' || v_step;
	END;
	
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.cancel_ride_request(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.cancel_ride_request(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.cancel_ride_request(character varying, character varying) TO carpool_role;


CREATE OR REPLACE FUNCTION nov2016.rider_cancel_confirmed_match(
    UUID_driver character varying(50),
	UUID_rider character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

DECLARE                                                   

BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM nov2016.match m, stage.websubmission_rider r
	WHERE m.uuid_driver = UUID_driver
	AND m.uuid_rider = UUID_rider
	AND m.state = 'MatchConfirmed'   -- We can confirmed only a 
	AND m.uuid_rider = r."UUID"
	AND (LOWER(r."RiderLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."RiderPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Confirmed Match found for those parameters.';
	END IF;

	return '';
    END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.rider_cancel_confirmed_match(character varying, character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.rider_cancel_confirmed_match(character varying, character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.rider_cancel_confirmed_match(character varying, character varying, character varying) TO carpool_role;

CREATE OR REPLACE FUNCTION nov2016.cancel_drive_offer(
    UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

DECLARE                                                   
  
BEGIN 


	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM stage.websubmission_driver r
	WHERE r."UUID" = UUID
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Drive Offer found for those parameters';
	END IF;

    RETURN '';                               
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.cancel_drive_offer(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.cancel_drive_offer(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.cancel_drive_offer(character varying, character varying) TO carpool_role;


CREATE OR REPLACE FUNCTION nov2016.driver_cancel_confirmed_match(
    UUID_driver character varying(50),
	UUID_rider character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

DECLARE                                                   
    
BEGIN 
	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM nov2016.match m, stage.websubmission_driver r
	WHERE m.uuid_driver = UUID_driver
	AND m.uuid_rider = UUID_rider
	AND m.state = 'MatchConfirmed'   -- We can confirmed only a 
	AND m.uuid_driver = r."UUID"
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Confirmed Match found for those parameters.';
	END IF;

	RETURN '';
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.driver_cancel_confirmed_match(character varying, character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_cancel_confirmed_match(character varying, character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_cancel_confirmed_match(character varying, character varying, character varying) TO carpool_role;


CREATE OR REPLACE FUNCTION nov2016.confirm_match(
    UUID_driver character varying(50),
	UUID_rider character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

DECLARE                                                   
      
BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM nov2016.match m, stage.websubmission_driver r
	WHERE m.uuid_driver = UUID_driver
	AND m.uuid_rider = UUID_rider
	AND m.state = 'MatchProposed'   -- We can confirmed only a 
	AND m.uuid_driver = r."UUID"
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Match can be confirmed with for those parameters';
	END IF;

	RETURN '';

    END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.confirm_match(character varying, character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.confirm_match(character varying, character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.confirm_match(character varying, character varying, character varying) TO carpool_role;
