-- actions by rider
--carpoolvote.rider_cancel_ride_request(UUID, phone number or lastname ?, OUT out_error_code INTEGER, OUT out_error_text TEXT)
--carpoolvote.rider_cancel_confirmed_match(UUID_driver, UUID_rider, rider’s phone number or rider’s lastname ?, OUT out_error_code INTEGER, OUT out_error_text TEXT)
--carpoolvote.rider_update_match_details(UUID_driver, UUID_rider, rider’s phone number or rider’s lastname ?, rider_notes TEXT, OUT out_error_code INTEGER, OUT out_error_text TEXT))

-- actions by driver
--carpoolvote.driver_cancel_drive_offer(UUID, phone number or lastname ?, OUT out_error_code INTEGER, OUT out_error_text TEXT)
--carpoolvote.driver_cancel_confirmed_match(UUID_driver, UUID_rider, driverr’s phone number or driver’s lastname ?, OUT out_error_code INTEGER, OUT out_error_text TEXT)
--carpoolvote.driver_confirm_match(UUID_driver, UUID_rider, driver’s phone number or driver’s lastname ?, OUT out_error_code INTEGER, OUT out_error_text TEXT)
--carpoolvote.driver_pause_match(UUID, phone number or lastname ?, OUT out_error_code INTEGER, OUT out_error_text TEXT)
--carpoolvote.driver_update_match_details(UUID_driver, UUID_rider, driver’s phone number or rider’s lastname ?, driver_notes TEXT, OUT out_error_code INTEGER, OUT out_error_text TEXT))

-- functions return out_error_code=0 in case of success. If <>0, out_error_text contains error description


-- State transitions ---

-- [0]    -----> submit_new_driver [1] driver : Pending [OK]
-- [0]    -----> submit_new_rider  [2] rider : Pending [OK]
-- [0]    -----> submit_new_helper [3] 

-- [1][2] -----> match             [4] match : MatchProposed, driver : MatchProposed, rider : MatchProposed [OK]

-- [1]    -----> driver_cancel_drive_offer  [5]  driver : Canceled [OK]
-- [2]    -----> rider_cancel_ride_request  [6]  rider : Canceled  [OK]

-- [4]    -----> driver_cancel_drive_offer  [7]  match : Canceled, driver : Canceled, rider : Pending/MatchProposed [OK]
-- [4]    -----> rider_cancel_ride_request  [8]  match : Canceled, driver : Pending/MatchProposed, rider : Canceled

-- [5]    -----> driver_cancel_drive_offer  [5]  driver : Canceled [OK]
-- [6]    -----> rider_cancel_ride_request  [6]  rider : Canceled  [OK]

-- [4]    -----> driver_confirm_match       [9]  match : MatchConfirmed, driver : MatchConfirmed, rider : MatchConfirmed [OK]

-- [9]    -----> driver_cancel_confirmed_match [10]  match : Canceled, driver : MatchProposed/Pending, rider : MatchProposed/Pending [OK]
-- [9]    -----> rider_cancel_confirmed_match  [11]  match : Canceled, driver : MatchProposed/Pending, rider : MatchProposed/Pending [OK]
-- [10]   -----> driver_cancel_drive_offer  [5] [OK]
-- [11]   -----> rider_cancel_ride_request  [6] [OK]

-- [9]    -----> driver_cancel_drive_offer  [5] [OK]
-- [9]    -----> rider_cancel_ride_request  [6]  match : Canceled, rider : Canceled, driver : Pending [OK]

-- Common function to update status of ride request record

SET search_path = carpoolvote, pg_catalog;


CREATE OR REPLACE FUNCTION carpoolvote.validate_name_or_phone(
	a_confirmation_parameter character varying,
	a_last_name character varying,
	a_phone_number character varying
	) RETURNS boolean AS
$BODY$
BEGIN

RETURN (LOWER(a_last_name) = LOWER(a_confirmation_parameter)
		OR (regexp_replace( regexp_replace(COALESCE(a_phone_number, ''),'(\D)', '', 'g'), '^1', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace( regexp_replace(COALESCE(a_confirmation_parameter, ''),'(\D)', '', 'g'), '^1', '', 'g'))); -- strips everything that is not numeric and the first one 
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.validate_name_or_phone(character varying, character varying, character varying)
	OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.validate_name_or_phone(	character varying, character varying, character varying) 
	TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.validate_name_or_phone( character varying, character varying, character varying)
	TO carpool_role;

  
  
-- 
-- submit_new_rider
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 1  : ERROR - Input is disabled
-- 2  : ERROR - Input validation
CREATE OR REPLACE FUNCTION carpoolvote.submit_new_rider(
	a_IPAddress character varying,
    a_RiderFirstName character varying,
    a_RiderLastName character varying,
    a_RiderEmail character varying,
    a_RiderPhone character varying,
    a_RiderCollectionZIP character varying,
    a_RiderDropOffZIP character varying,
    a_AvailableRideTimesLocal character varying,
    a_TotalPartySize integer,
    a_TwoWayTripNeeded boolean,
    a_RiderIsVulnerable boolean,
    a_RiderWillNotTalkPolitics boolean,
    a_PleaseStayInTouch boolean,
    a_NeedWheelchair boolean,
    a_RiderPreferredContact character varying,
    a_RiderAccommodationNotes character varying,
    a_RiderLegalConsent boolean,
    a_RiderWillBeSafe boolean,
	a_RiderCollectionStreetNumber character varying,
    a_RiderCollectionAddress character varying,
    a_RiderDestinationAddress character varying,
	a_RidingOnBehalfOfOrganization boolean,
	a_RidingOBOOrganizationName character varying,
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$
DECLARE
	v_step character varying(200);
	ride_times_rider text[];
	b_rider_all_times_expired  boolean := TRUE;
	rider_time text;
	start_ride_time timestamp without time zone;
	end_ride_time timestamp without time zone;
    uuid_organization character varying(50);

	a_ip inet;
BEGIN	

	out_uuid := '';
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';

	BEGIN
		v_step := 'S1';
		IF  LOWER(COALESCE(carpoolvote.get_param_value('input.rider.enabled'), 'false')) = LOWER('false')
		THEN
			out_error_code := carpoolvote.f_INPUT_DISABLED();
			out_error_text := 'Submission of new Rider is disabled.';
			RETURN;
		END IF;
	
		v_step := 'S2';
		BEGIN
			SELECT inet(a_IPAddress) into a_ip;
		EXCEPTION WHEN invalid_text_representation
		THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid IPAddress: ' || a_IPAddress;
			RETURN;
		END;
		
		v_step := 'S3';
		SELECT * FROM carpoolvote.validate_availabletimeslocal(a_AvailableRideTimesLocal) into out_error_code, out_error_text;
		IF out_error_code <> 0
		THEN
			RETURN;
		END IF;

	
		-- zip code verification
		v_step := 'S4';
		IF NOT EXISTS
			(SELECT 1 FROM carpoolvote.zip_codes z where z.zip = a_RiderCollectionZIP AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
		THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid/Not Found RiderCollectionZIP:' || a_RiderCollectionZIP;
			RETURN;
		END IF;

		v_step := 'S5';
		IF NOT EXISTS 
			(SELECT 1 FROM carpoolvote.zip_codes z WHERE z.zip = a_RiderDropOffZIP AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
		THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid/Not Found RiderDropOffZIP:' || a_RiderDropOffZIP;
			RETURN;
		END IF;	
	
		v_step := 'S6';
		IF (a_TotalPartySize is null) or (a_TotalPartySize <= 0) THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid TotalPartySize: ' || a_TotalPartySize;
			RETURN;
		END IF;

		v_step := 'S7';
		IF a_RidingOnBehalfOfOrganization IS NOT NULL and a_RidingOnBehalfOfOrganization IS TRUE
		THEN 
			IF a_RidingOBOOrganizationName IS NOT NULL and EXISTS (SELECT 1 FROM carpoolvote.organization o WHERE o."OrganizationName" = a_RidingOBOOrganizationName)
			THEN
				SELECT "UUID" FROM carpoolvote.organization o WHERE o."OrganizationName" = a_RidingOBOOrganizationName into uuid_organization;
			ELSE
				IF a_RidingOBOOrganizationName IS NULL 
				THEN
					out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
					out_error_text := 'Invalid RidingOBOOrganizationName';
					RETURN;
				ELSE 
					out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
					out_error_text := 'Not Found RidingOBOOrganizationName:' || a_RidingOBOOrganizationName;
					RETURN;
				END IF;
			END IF;
		END IF;	

		
		v_step := 'S8';
		out_uuid := carpoolvote.gen_random_uuid();
		INSERT INTO carpoolvote.rider(
		"UUID", "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail", "RiderPhone", "RiderCollectionZIP",
		"RiderDropOffZIP", "AvailableRideTimesLocal", "TotalPartySize", "TwoWayTripNeeded", "RiderIsVulnerable",
		"RiderWillNotTalkPolitics", "PleaseStayInTouch", "NeedWheelchair", "RiderPreferredContact",
		"RiderAccommodationNotes", "RiderLegalConsent", "RiderWillBeSafe", "RiderCollectionStreetNumber", "RiderCollectionAddress", "RiderDestinationAddress", "uuid_organization")
		VALUES (
		out_uuid, a_IPAddress, a_RiderFirstName, a_RiderLastName, a_RiderEmail, a_RiderPhone, a_RiderCollectionZIP,
		a_RiderDropOffZIP, a_AvailableRideTimesLocal, a_TotalPartySize, a_TwoWayTripNeeded, a_RiderIsVulnerable,
		a_RiderWillNotTalkPolitics, a_PleaseStayInTouch, a_NeedWheelchair, a_RiderPreferredContact,
		a_RiderAccommodationNotes, a_RiderLegalConsent, a_RiderWillBeSafe, a_RiderCollectionStreetNumber, a_RiderCollectionAddress, a_RiderDestinationAddress, uuid_organization);

		v_step := 'S9';
		SELECT * FROM carpoolvote.notify_new_rider(out_uuid) INTO out_error_code, out_error_text;
		
		RETURN;
	EXCEPTION WHEN OTHERS
	THEN
		out_uuid := '';
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in submit_new_rider, ' || v_step ||  ' (' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
	

	
END  
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.submit_new_rider(character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying, character varying,
    character varying, boolean, character varying, out character varying, out integer, out text)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider(	character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying, character varying,
    character varying, boolean, character varying, out character varying, out integer, out text) TO carpool_web_role;
	
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider( character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying, character varying,
    character varying, boolean, character varying, out character varying, out integer, out text) TO carpool_role;


-- 
-- submit_new_rider
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 1  : ERROR - Input is disabled
-- 2  : ERROR - Input validation
CREATE OR REPLACE FUNCTION carpoolvote.submit_new_rider(
	a_IPAddress character varying,
    a_RiderFirstName character varying,
    a_RiderLastName character varying,
    a_RiderEmail character varying,
    a_RiderPhone character varying,
    a_RiderCollectionZIP character varying,
    a_RiderDropOffZIP character varying,
    a_AvailableRideTimesLocal character varying,
    a_TotalPartySize integer,
    a_TwoWayTripNeeded boolean,
    a_RiderIsVulnerable boolean,
    a_RiderWillNotTalkPolitics boolean,
    a_PleaseStayInTouch boolean,
    a_NeedWheelchair boolean,
    a_RiderPreferredContact character varying,
    a_RiderAccommodationNotes character varying,
    a_RiderLegalConsent boolean,
    a_RiderWillBeSafe boolean,
    a_RiderCollectionAddress character varying,
    a_RiderDestinationAddress character varying,
	a_RidingOnBehalfOfOrganization boolean,
	a_RidingOBOOrganizationName character varying,
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$
BEGIN	

SELECT * FROM carpoolvote.submit_new_rider(
	a_IPAddress,
    a_RiderFirstName,
    a_RiderLastName,
    a_RiderEmail,
    a_RiderPhone,
    a_RiderCollectionZIP,
    a_RiderDropOffZIP,
    a_AvailableRideTimesLocal,
    a_TotalPartySize,
    a_TwoWayTripNeeded,
    a_RiderIsVulnerable,
    a_RiderWillNotTalkPolitics,
    a_PleaseStayInTouch,
    a_NeedWheelchair,
    a_RiderPreferredContact,
    a_RiderAccommodationNotes,
    a_RiderLegalConsent,
    a_RiderWillBeSafe,
	NULL,  -- the street number
    a_RiderCollectionAddress,
    a_RiderDestinationAddress,
	a_RidingOnBehalfOfOrganization,
	a_RidingOBOOrganizationName) INTO
	out_uuid,
	out_error_code,
	out_error_text;
	
	RETURN;
	
END  
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.submit_new_rider(character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying,
    character varying, boolean, character varying, out character varying, out integer, out text)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider(	character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying,
    character varying, boolean, character varying, out character varying, out integer, out text) TO carpool_web_role;
	
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider( character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying,
    character varying, boolean, character varying, out character varying, out integer, out text) TO carpool_role;
	

-- 
-- 
-- submit_new_driver
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 1  : ERROR - Input is disabled
-- 2  : ERROR - Input validation
CREATE OR REPLACE FUNCTION carpoolvote.submit_new_driver(
	a_IPAddress character varying,
	a_DriverCollectionZIP character varying,
	a_DriverCollectionRadius integer,
	a_AvailableDriveTimesLocal character varying,
	a_DriverCanLoadRiderWithWheelchair boolean,
	a_SeatCount integer,
	a_DriverLicenseNumber character varying,
	a_DriverFirstName character varying,
	a_DriverLastName character varying,
	a_DriverEmail character varying,
	a_DriverPhone character varying,
	a_DrivingOnBehalfOfOrganization boolean,
	a_DrivingOBOOrganizationName character varying,
	a_RidersCanSeeDriverDetails boolean,
	a_DriverWillNotTalkPolitics boolean,
	a_PleaseStayInTouch boolean,
	a_DriverPreferredContact character varying,
	a_DriverWillTakeCare boolean,
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$
DECLARE
	v_step character varying(200);
    uuid_organization character varying(50);
	
	a_ip inet;
BEGIN	
	
	out_uuid := '';
	out_error_code := 0;
	out_error_text := '';
	
	BEGIN

		v_step := 'S1';
		IF  LOWER(COALESCE(carpoolvote.get_param_value('input.driver.enabled'), 'false')) = LOWER('false')
		THEN
			out_error_code := carpoolvote.f_INPUT_DISABLED();
			out_error_text := 'Submission of new Driver is disabled.';
			RETURN;
		END IF;

		v_step := 'S2';
		BEGIN
			SELECT inet(a_IPAddress) into a_ip;
		EXCEPTION WHEN invalid_text_representation
		THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid IPAddress: ' || a_IPAddress;
			RETURN;
		END;
		
		v_step := 'S3';
		IF NOT EXISTS 
			(SELECT 1 FROM carpoolvote.zip_codes z where z.zip = a_DriverCollectionZIP AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
		THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid/Not Found DriverCollectionZIP:' || a_DriverCollectionZIP;
			RETURN;
		END IF; 	

		v_step := 'S4';
		SELECT * FROM carpoolvote.validate_availabletimeslocal(a_AvailableDriveTimesLocal) into out_error_code, out_error_text;
		IF out_error_code <> 0
		THEN
			RETURN;
		END IF;
		
		v_step := 'S5';
		IF (a_DriverCollectionRadius is null) or (a_DriverCollectionRadius <= 0) 
		or (COALESCE(carpoolvote.get_param_value('radius.max'), '100')::int < a_DriverCollectionRadius) THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid DriverCollectionRadius';
			RETURN;
		END IF;

		v_step := 'S6';
		IF (a_SeatCount is null) or (a_SeatCount <= 0) THEN
			out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
			out_error_text := 'Invalid SeatCount';
			RETURN;
		END IF;
		
		v_step := 'S7';
		IF a_DrivingOnBehalfOfOrganization IS NOT NULL and a_DrivingOnBehalfOfOrganization IS TRUE
		THEN 
			IF a_DrivingOBOOrganizationName IS NOT NULL and EXISTS (SELECT 1 FROM carpoolvote.organization o WHERE o."OrganizationName" = a_DrivingOBOOrganizationName)
			THEN
				SELECT "UUID" FROM carpoolvote.organization o WHERE o."OrganizationName" = a_DrivingOBOOrganizationName into uuid_organization;
			ELSE
				IF a_DrivingOBOOrganizationName IS NULL 
				THEN
					out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
					out_error_text := 'Invalid DrivingOBOOrganizationName';
					RETURN;
				ELSE 
					out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
					out_error_text := 'Not Found DrivingOBOOrganizationName:' || a_DrivingOBOOrganizationName;
					RETURN;
				END IF;
			END IF;
		END IF;	
		
		
		v_step := 'S8';
		out_uuid := carpoolvote.gen_random_uuid();
		INSERT INTO carpoolvote.driver(
		"UUID", "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", "AvailableDriveTimesLocal", 
		"DriverCanLoadRiderWithWheelchair", "SeatCount", "DriverLicenseNumber", 
		"DriverFirstName", "DriverLastName", "DriverEmail", "DriverPhone",
		"DrivingOnBehalfOfOrganization", "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails",
		"DriverWillNotTalkPolitics", "PleaseStayInTouch", "DriverPreferredContact", "DriverWillTakeCare", "uuid_organization")
		VALUES (
		out_uuid, 
		a_IPAddress, a_DriverCollectionZIP, a_DriverCollectionRadius, a_AvailableDriveTimesLocal, 
		a_DriverCanLoadRiderWithWheelchair, a_SeatCount, a_DriverLicenseNumber, 
		a_DriverFirstName, a_DriverLastName, a_DriverEmail, a_DriverPhone,
		a_DrivingOnBehalfOfOrganization, a_DrivingOBOOrganizationName, a_RidersCanSeeDriverDetails,
		a_DriverWillNotTalkPolitics, a_PleaseStayInTouch, a_DriverPreferredContact, a_DriverWillTakeCare, uuid_organization
		);
		
		v_step := 'S9';
		SELECT * FROM carpoolvote.notify_new_driver(out_uuid) INTO out_error_code, out_error_text;
	
		RETURN;
	EXCEPTION WHEN OTHERS
	THEN
		out_uuid := '';
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in submit_new_driver, ' || v_step || ' (' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
	

	
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.submit_new_driver(
	character varying, character varying, integer, character varying,
	boolean, integer, character varying, character varying, character varying,
	character varying, character varying, boolean, character varying,
	boolean, boolean, boolean, character varying, boolean,
	OUT character varying, OUT INTEGER, OUT TEXT)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_driver(	
character varying, character varying, integer, character varying,
	boolean, integer, character varying, character varying, character varying,
	character varying, character varying, boolean, character varying,
	boolean, boolean, boolean, character varying, boolean,
	OUT character varying, OUT INTEGER, OUT TEXT) TO carpool_web_role;
	
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_driver( 
character varying, character varying, integer, character varying,
	boolean, integer, character varying, character varying, character varying,
	character varying, character varying, boolean, character varying,
	boolean, boolean, boolean, character varying, boolean,
	OUT character varying, OUT INTEGER, OUT TEXT) TO carpool_role;
	

-- 
-- 
-- submit_new_helper
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 1  : ERROR - Input is disabled
-- 2  : ERROR - Input validation
CREATE OR REPLACE FUNCTION carpoolvote.submit_new_helper(
    a_helpername character varying,
    a_helperemail character varying,
    a_helpercapability character varying[],
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$
DECLARE
	v_step character varying(200);
BEGIN	

	out_uuid := '';
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	
	BEGIN

		IF  LOWER(COALESCE(carpoolvote.get_param_value('input.helper.enabled'), 'false')) = LOWER('false')
		THEN
			
			out_error_code := carpoolvote.f_INPUT_DISABLED();
			out_error_text := 'Submission of new Helper is disabled.';
			RETURN;
		END IF;
	
		out_uuid := carpoolvote.gen_random_uuid();
	
		INSERT INTO carpoolvote.helper(
			"UUID", helpername, helperemail, helpercapability)
		VALUES(
			out_uuid, a_helpername, a_helperemail, a_helpercapability
		);
		
		out_error_code := carpoolvote.f_SUCCESS();
		out_error_text := '';
	
		RETURN;
		
	
	EXCEPTION WHEN OTHERS
	THEN
		out_uuid := '';
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in submit_new_helper(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
	
	
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.submit_new_helper(
    character varying, character varying, character varying[],
	OUT character varying, OUT INTEGER, OUT TEXT)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_helper(	
	character varying, character varying, character varying[],
	OUT character varying, OUT INTEGER, OUT TEXT) TO carpool_web_role;
	
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_helper( 
	character varying, character varying, character varying[],
	OUT character varying, OUT INTEGER, OUT TEXT) TO carpool_role;
	
	

CREATE OR REPLACE FUNCTION carpoolvote.update_ride_request_status(
    a_UUID character varying(50)	)
  RETURNS character varying AS
$BODY$
DECLARE
	v_step character varying(200);
BEGIN	

	BEGIN
	v_step := 'S1';
	
	-- If there is at least one match in MatchConfirmed status -> MatchConfirmed
	IF EXISTS ( 
		SELECT 1
		FROM carpoolvote.match
		WHERE uuid_rider = a_UUID
		AND status='MatchConfirmed'
	)
	THEN	
		v_step := 'S2';
		UPDATE carpoolvote.rider
		SET status='MatchConfirmed'
		WHERE "UUID" = a_UUID
		AND status NOT IN ('Canceled', 'Expired');
	ELSIF EXISTS (   -- If there is at least one match in MatchProposed or MatchConfirmed -> MatchProposed
		SELECT 1
		FROM carpoolvote.match
		WHERE uuid_rider = a_UUID
		AND status = 'MatchProposed'
	)
	THEN
		v_step := 'S3';
		UPDATE carpoolvote.rider
		SET status='MatchProposed'
		WHERE "UUID" = a_UUID
		AND status NOT IN ('Canceled', 'Expired');	
	ELSE               -- default, is Pending
		v_step := 'S4';
		UPDATE carpoolvote.rider
		SET status='Pending'
		WHERE "UUID" = a_UUID 
		AND status NOT IN ('Canceled', 'Expired');
	END IF;
		
	RETURN '';
	
	EXCEPTION WHEN OTHERS
	THEN
		RAISE NOTICE 'Exception occurred during processing: update_ride_request_status,%', v_step || '(' || SQLSTATE || ')' || SQLERRM;
		return 'Exception occurred during processing: update_ride_request_status,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
	END;
			
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.update_ride_request_status(character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.update_ride_request_status(character varying) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.update_ride_request_status(character varying) TO carpool_role;


-- Common function to update status of drive offer record
CREATE OR REPLACE FUNCTION carpoolvote.update_drive_offer_status(
    a_UUID character varying(50)	)
  RETURNS character varying AS
$BODY$
DECLARE
	v_step character varying(200);
	rider_total_party_size integer;
BEGIN	

	BEGIN
	v_step := 'S1';
	
	-- If there is at least one match in MatchConfirmed status -> MatchConfirmed
	IF EXISTS ( 
		SELECT 1
		FROM carpoolvote.match
		WHERE uuid_driver = a_UUID
		AND status='MatchConfirmed'
	)
	THEN	
		v_step := 'S2';
		UPDATE carpoolvote.driver
		SET status='MatchConfirmed'
		WHERE "UUID" = a_UUID
		AND status NOT IN ('Canceled', 'Expired');

		SELECT rider."TotalPartySize" INTO rider_total_party_size
		FROM carpoolvote.match 
		inner join carpoolvote.rider on (carpoolvote.match.uuid_rider = carpoolvote.rider."UUID") 
		inner join carpoolvote.driver on carpoolvote.match.uuid_driver = carpoolvote.driver."UUID"
		where driver."UUID" = a_UUID;

		INSERT into carpoolvote.driver(
			"SeatCount", "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius",
			"AvailableDriveTimesLocal", "DriverCanLoadRiderWithWheelchair",
			"DriverLicenseNumber", "DriverFirstName", "DriverLastName",
			"DriverEmail", "DriverPhone", "DrivingOnBehalfOfOrganization",
			"DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics",
			"ReadyToMatch", "PleaseStayInTouch", status, created_ts, last_updated_ts,
			status_info, "DriverPreferredContact", "DriverWillTakeCare",
			uuid_organization)
		SELECT
			(driver."SeatCount" - rider."TotalPartySize") AS "SeatCount", driver."IPAddress", "DriverCollectionZIP", "DriverCollectionRadius",
			"AvailableDriveTimesLocal", "DriverCanLoadRiderWithWheelchair",
			"DriverLicenseNumber", "DriverFirstName", "DriverLastName",
			"DriverEmail", "DriverPhone", "DrivingOnBehalfOfOrganization",
			"DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics",
			driver."ReadyToMatch", driver."PleaseStayInTouch", 'Pending', carpoolvote.driver.created_ts, carpoolvote.driver.last_updated_ts,
			carpoolvote.driver.status_info, "DriverPreferredContact", "DriverWillTakeCare",
			carpoolvote.driver.uuid_organization 
		FROM carpoolvote.match 
		inner join carpoolvote.rider on (carpoolvote.match.uuid_rider = carpoolvote.rider."UUID") 
		inner join carpoolvote.driver on carpoolvote.match.uuid_driver = carpoolvote.driver."UUID"
		where rider."TotalPartySize" < driver."SeatCount" and driver.status='MatchConfirmed' and driver."UUID" = a_UUID;

		UPDATE carpoolvote.driver 
		SET "SeatCount" = rider_total_party_size 
		where driver.status='MatchConfirmed' and driver."UUID" = a_UUID;

	ELSIF EXISTS (   -- If there is at least one match in MatchProposed or MatchConfirmed -> MatchProposed
		SELECT 1
		FROM carpoolvote.match
		WHERE uuid_driver = a_UUID
		AND status = 'MatchProposed'
	)
	THEN
		v_step := 'S3';
		UPDATE carpoolvote.driver
		SET status='MatchProposed'
		WHERE "UUID" = a_UUID
		AND status NOT IN ('Canceled', 'Expired');
	
	ELSE               -- default, is Pending
		v_step := 'S4';
		UPDATE carpoolvote.driver
		SET status='Pending'
		WHERE "UUID" = a_UUID
		AND status NOT IN ('Canceled', 'Expired');
		
	END IF;
		
	RETURN '';
	
	EXCEPTION WHEN OTHERS
	THEN
		RAISE NOTICE 'Exception occurred during processing: update_drive_offer_status,%', v_step || '(' || SQLSTATE || ')' || SQLERRM;
		return 'Exception occurred during processing: update_drive_offer_status,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
	END;
			
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.update_drive_offer_status(character varying) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.update_drive_offer_status(character varying) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.update_drive_offer_status(character varying) TO carpool_role;


--------------------------------------------------------
-- USER STORY 003 - RIDER cancels ride request
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 2  : ERROR - Input validation
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.rider_cancel_ride_request(
    a_uuid_rider character varying(50),
    confirmation_parameter character varying(255),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
  AS
$BODY$

DECLARE                                                   
	ride_request_row carpoolvote.rider%ROWTYPE;
	drive_offer_row carpoolvote.driver%ROWTYPE;
	match_row carpoolvote.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
	
BEGIN 

	out_error_code :=  carpoolvote.f_SUCCESS();
	out_error_text := '';

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.rider r
	WHERE r."UUID" = a_uuid_rider
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."RiderLastName", r."RiderPhone")
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'No Ride Request found for those parameters';
		RETURN;
	END IF;
	
	BEGIN
		v_step := 'S0';
		SELECT * INTO ride_request_row
		FROM carpoolvote.rider
		WHERE "UUID" = a_uuid_rider;
	
		v_step := 'S1';
		FOR match_row IN SELECT * FROM carpoolvote.match m
			WHERE m.uuid_rider = a_uuid_rider
		
		LOOP
			v_step := 'S2';
			IF match_row.status = 'MatchConfirmed'
			THEN
				SELECT * INTO drive_offer_row
				FROM carpoolvote.driver
				WHERE "UUID" = match_row.uuid_driver;
				
				v_step := 'S3';   -- Cancellation Notification to confirmed drivers
				SELECT * FROM carpoolvote.notify_driver_ride_cancelled_by_rider(drive_offer_row."UUID", a_uuid_rider) INTO out_error_code, out_error_text;
			END IF;
			
			v_step := 'S4';
			UPDATE carpoolvote.match
			SET status = 'Canceled'
			WHERE uuid_rider = match_row.uuid_rider
			AND uuid_driver = match_row.uuid_driver;
			
			v_step := 'S5';
			v_return_text := carpoolvote.update_drive_offer_status(match_row.uuid_driver);
			IF  v_return_text != ''
			THEN
				v_step := v_step || ' ' || v_return_text;
				RAISE EXCEPTION '%', v_return_text;
			END IF;
		
		END LOOP;
		
		v_step := 'S6';
		UPDATE carpoolvote.match
		SET status = 'Canceled'
		WHERE uuid_rider = a_uuid_rider;
		
		v_step := 'S7';
		-- Update Ride Request to Canceled
		UPDATE carpoolvote.rider
		SET status='Canceled'
		WHERE "UUID" = a_uuid_rider;
		
		-- Send cancellation notice to rider
		v_step := 'S8';
		SELECT * FROM carpoolvote.notify_rider_ride_cancelled_by_rider(a_uuid_rider) INTO out_error_code, out_error_text;
		
		out_error_text := '';
		RETURN;
    
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := -1;
		out_error_text := 'Exception occurred during processing: rider_cancel_ride_request,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
	
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.rider_cancel_ride_request(
	character varying, character varying,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_ride_request(
	character varying, character varying,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_ride_request(
	character varying, character varying,
	out integer, out text) TO carpool_role;



--------------------------------------------------------
-- USER STORY 004 - RIDER cancels a confirmed match
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 2  : ERROR - Input validation
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.rider_cancel_confirmed_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
    confirmation_parameter character varying(255),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
  AS
$BODY$

DECLARE                                                   
	ride_request_row carpoolvote.rider%ROWTYPE;
	drive_offer_row carpoolvote.driver%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
	
BEGIN 

	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.match m, carpoolvote.rider r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.status = 'MatchConfirmed'   -- We can cancel only a Confirmed match
	AND m.uuid_rider = r."UUID"
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."RiderLastName", r."RiderPhone")
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'No Confirmed Match found for those parameters.';
		return ;
	END IF;

	BEGIN
		v_step := 'S0';
		UPDATE carpoolvote.match
		SET status='Canceled'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver;
	
		v_step := 'S1';
		SELECT * INTO drive_offer_row
		FROM carpoolvote.driver
		WHERE "UUID" = a_UUID_driver;	
		
		SELECT * INTO ride_request_row
		FROM carpoolvote.rider
		WHERE "UUID" = a_UUID_rider;	

		
		v_step := 'S2';
		-- notify driver
		SELECT * FROM carpoolvote.notify_driver_confirmed_match_cancelled_by_rider(a_UUID_driver, a_UUID_rider) INTO out_error_code, out_error_text;


		v_step := 'S3';
		v_return_text := carpoolvote.update_drive_offer_status(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
	
		v_step := 'S4';
		v_return_text := carpoolvote.update_ride_request_status(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;


		-- Send cancellation notice to rider
		v_step := 'S8';
		SELECT * FROM carpoolvote.notify_rider_confirmed_match_cancelled_by_rider(a_UUID_driver, a_UUID_rider) INTO out_error_code, out_error_text;
				
		return;
	
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Exception occurred during processing: rider_cancel_confirmed_match,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;

END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.rider_cancel_confirmed_match(character varying, character varying, character varying,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_confirmed_match(character varying, character varying, character varying,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_confirmed_match(character varying, character varying, character varying,
	out integer, out text) TO carpool_role;

--------------------------------------------------------
-- USER STORY 013 - DRIVER cancels driver offer
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 2  : ERROR - Input validation
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_cancel_drive_offer(
    a_UUID character varying(50),
    confirmation_parameter character varying(255),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
	AS
$BODY$

DECLARE                                                   
	ride_request_row carpoolvote.rider%ROWTYPE;
	drive_offer_row carpoolvote.driver%ROWTYPE;
	match_row carpoolvote.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
	
BEGIN 

	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	
	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.driver r
	WHERE r."UUID" = a_UUID
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."DriverLastName", r."DriverPhone")
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'No Drive Offer found for those parameters';
		return;
	END IF;

	BEGIN
		v_step := 'S0';
		SELECT * INTO drive_offer_row
		FROM carpoolvote.driver
		WHERE "UUID" = a_UUID;	
	
		v_step := 'S1';
		FOR match_row IN SELECT * FROM carpoolvote.match
			WHERE uuid_driver = a_UUID
		
		LOOP
			v_step := 'S2';
			IF match_row.status = 'MatchConfirmed'
			THEN
				SELECT * INTO ride_request_row
				FROM carpoolvote.rider
				WHERE "UUID" = match_row.uuid_rider;	
				v_step := 'S3';
				SELECT * FROM carpoolvote.notify_rider_drive_cancelled_by_driver(drive_offer_row."UUID", ride_request_row."UUID") INTO out_error_code, out_error_text;
			END IF;

			v_step := 'S4';
			UPDATE carpoolvote.match
			SET status = 'Canceled'
			WHERE uuid_rider = match_row.uuid_rider
			AND uuid_driver = match_row.uuid_driver;
			
			v_step := 'S5';
			v_return_text := carpoolvote.update_ride_request_status(match_row.uuid_rider);
			IF  v_return_text != ''
			THEN
				v_step := v_step || ' ' || v_return_text;
				RAISE EXCEPTION '%', v_return_text;
			END IF;
		
		END LOOP;
		
		v_step := 'S6';
		UPDATE carpoolvote.match
		SET status = 'Canceled'
		WHERE uuid_driver = a_UUID;
		
		v_step := 'S7';
		-- Update Drive Offer to Canceled
		UPDATE carpoolvote.driver
		SET status='Canceled'
		WHERE "UUID" = a_UUID;

		-- Send cancellation notice to driver
		v_step := 'S8';
		SELECT * FROM carpoolvote.notify_driver_drive_cancelled_by_driver(a_UUID) into out_error_code, out_error_text;

		return;
    	
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Exception occurred during processing: driver_cancel_drive_offer,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;

END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_cancel_drive_offer(character varying, character varying,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_drive_offer(character varying, character varying,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_drive_offer(character varying, character varying,
	out integer, out text) TO carpool_role;

--------------------------------------------------------
-- USER STORY 014 - DRIVER cancels confirmed match
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 2  : ERROR - Input validation
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_cancel_confirmed_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
    confirmation_parameter character varying(255),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
	AS
$BODY$

DECLARE                                                   
    ride_request_row carpoolvote.rider%ROWTYPE;
	drive_offer_row carpoolvote.driver%ROWTYPE;
	match_row carpoolvote.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
	
BEGIN 

	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	
	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.match m, carpoolvote.driver r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.status = 'MatchConfirmed'   -- We can confirmed only a 
	AND m.uuid_driver = r."UUID"
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."DriverLastName", r."DriverPhone")
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'No Confirmed Match found for those parameters.';
		return;
	END IF;

	BEGIN
		v_step := 'S0';
		UPDATE carpoolvote.match
		SET status='Canceled'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver;
	
		v_step := 'S1';
		SELECT * INTO ride_request_row
		FROM carpoolvote.rider
		WHERE "UUID" = a_UUID_rider;	

		SELECT * INTO drive_offer_row
		FROM carpoolvote.driver
		WHERE "UUID" = a_UUID_driver;	

		
		v_step := 'S2';
		-- send cancellation notice to rider
		SELECT * FROM carpoolvote.notify_rider_confirmed_match_cancelled_by_driver(drive_offer_row."UUID", ride_request_row."UUID") INTO out_error_code, out_error_text;
		
		v_step := 'S3';
		v_return_text := carpoolvote.update_drive_offer_status(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
	
		v_step := 'S4';
		v_return_text := carpoolvote.update_ride_request_status(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
		
		
		v_step := 'S5';
		-- send cancellation notice to driver
		SELECT * FROM carpoolvote.notify_driver_confirmed_match_cancelled_by_driver(drive_offer_row."UUID", ride_request_row."UUID") INTO out_error_code, out_error_text;
		
		RETURN;
	
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Exception occurred during processing: driver_cancel_confirmed_match,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;

END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_cancel_confirmed_match(character varying, character varying, character varying,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_confirmed_match(character varying, character varying, character varying,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_confirmed_match(character varying, character varying, character varying,
	out integer, out text) TO carpool_role;

--------------------------------------------------------
-- USER STORY 015 - DRIVER confirms match
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 2  : ERROR - Input validation
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_confirm_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
    confirmation_parameter character varying(255),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
	AS
$BODY$

DECLARE                                                   
    ride_request_row carpoolvote.rider%ROWTYPE;
	drive_offer_row carpoolvote.driver%ROWTYPE;
	match_row carpoolvote.match%ROWTYPE;
	v_step character varying(200); 
	v_return_text character varying(200);	
	
BEGIN 


	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';

		
	-- input validation
	-- Verify that the match is still in MatchProposed
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.match m, carpoolvote.driver r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.status = 'MatchProposed'   -- We can confirmed only a 
	AND m.uuid_driver = r."UUID"
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."DriverLastName", r."DriverPhone")
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'No Match can be confirmed with those parameters';
		RETURN;
	END IF;

	-- Verify that the Rider is not MatchConfirmed yet
	-- Can't confirm twice the same ride request
	IF EXISTS (
	SELECT 1 
	FROM carpoolvote.rider
	WHERE "UUID" = a_UUID_rider
	AND status='MatchConfirmed'
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'Ride Request has already been confirmed by another driver.';
		RETURN;
	END IF;
	
	BEGIN
		v_step := 'S1';
		UPDATE carpoolvote.match
		SET status='MatchConfirmed'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver;
	
		v_step := 'S2, ' || a_UUID_driver;
		v_return_text := carpoolvote.update_drive_offer_status(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_step || v_return_text;
		END IF;
	
		v_step := 'S3, ' || a_UUID_rider;
		v_return_text := carpoolvote.update_ride_request_status(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_step || v_return_text;
		END IF;
		
		v_step := 'S3';
		SELECT * INTO ride_request_row
		FROM carpoolvote.rider
		WHERE "UUID" = a_UUID_rider;	
		
	
		v_step := 'S4';
		-- send confirmation notice to driver
		SELECT * INTO drive_offer_row
		FROM carpoolvote.driver
		WHERE "UUID" = a_UUID_driver;	
		
		v_step := 'S5';
		SELECT * FROM carpoolvote.notify_driver_match_confirmed_by_driver(a_UUID_driver, a_UUID_rider) INTO out_error_code, out_error_text;


		v_step := 'S6';
		SELECT * FROM carpoolvote.notify_rider_match_confirmed_by_driver(a_UUID_driver, a_UUID_rider) INTO out_error_code, out_error_text;
	
		RETURN;
	
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Exception occurred during processing: driver_confirm_match,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;


    END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_confirm_match(character varying, character varying, character varying,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirm_match(character varying, character varying, character varying,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirm_match(character varying, character varying, character varying,
	out integer, out text) TO carpool_role;


--------------------------------------------------------
-- USER STORY 016 - DRIVER pauses match
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 2  : ERROR - Input validation
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_pause_match(
    uuid_driver character varying(50),
    confirmation_parameter character varying(255),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
	AS
$BODY$

DECLARE                                                   
	v_step character varying(200); 
	
BEGIN 

	out_error_code := 0;
	out_error_text := '';

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.driver r
	WHERE r."UUID" = uuid_driver
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."DriverLastName", r."DriverPhone")
	)
	THEN
		out_error_code := 2;
		out_error_text := 'No Drive Offer found for those parameters'
		return;
	END IF;

	BEGIN
		v_step := 'S1';
		UPDATE carpoolvote.driver
			SET "ReadyToMatch" = False
			WHERE "UUID" = uuid_driver;
			
		return;
	
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := -1;
		out_error_text := 'Exception occurred during processing: driver_pause_match,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;


END  
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_pause_match(character varying, character varying,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_pause_match(character varying, character varying,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_pause_match(character varying, character varying,
	out integer, out text) TO carpool_role;



CREATE OR REPLACE FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) RETURNS SETOF json
    LANGUAGE sql STABLE
    AS $$

        SELECT row_to_json(s)
        FROM ( 
            SELECT * from
            carpoolvote.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchStatus" = 'MatchConfirmed'
        ) s ;

$$;


ALTER FUNCTION carpoolvote.driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_exists(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE OR REPLACE FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	drive_offer_row carpoolvote.driver%ROWTYPE;
	v_step character varying(200); 
	v_return_text character varying(200);	
	
BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.driver r
	WHERE r."UUID" = a_UUID
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."DriverLastName", r."DriverPhone")
	)
	THEN
		return 'No Drive Offer found for those parameters';
	END IF;

	return '';
	
END  

$$;


ALTER FUNCTION carpoolvote.driver_exists(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_info(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE OR REPLACE FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	drive_offer_row carpoolvote.driver%ROWTYPE;
	v_step character varying(200); 
	v_return_text character varying(200);	
	d_row carpoolvote.driver%ROWTYPE;
	
BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.driver r
	WHERE r."UUID" = a_UUID
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."DriverLastName", r."DriverPhone")
	)
	THEN
		-- return 'No Drive Offer found for those parameters';
       RETURN row_to_json(d_row);
	END IF;

       SELECT * INTO
           d_row
       FROM
           carpoolvote.driver
       WHERE
           "UUID" = a_uuid;

       RETURN row_to_json(d_row);
	
END  

$$;


ALTER FUNCTION carpoolvote.driver_info(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;


--
-- Name: driver_proposed_matches(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE OR REPLACE FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) RETURNS SETOF json
    LANGUAGE sql STABLE
    AS $$

-- DECLARE                                                   
--BEGIN 

        SELECT row_to_json(s)
        FROM ( 
            SELECT * from
            carpoolvote.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchStatus" = 'MatchProposed'
        ) s ;

--END  

$$;


ALTER FUNCTION carpoolvote.driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;


--
-- Name: rider_confirmed_match(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE OR REPLACE FUNCTION carpoolvote.rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	r_row carpoolvote.vw_rider_matches%ROWTYPE;

BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.rider r
	WHERE r."UUID" = a_UUID
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."RiderLastName", r."RiderPhone")
	)
	THEN
        RETURN row_to_json(r_row);
	END IF;

        SELECT * INTO
            r_row
        FROM
            carpoolvote.vw_rider_matches
        WHERE
                uuid_rider = a_uuid
            AND "matchStatus" = 'MatchConfirmed';
            -- AND "matchStatus" = 'Canceled';

       RETURN row_to_json(r_row);

END  

$$;


ALTER FUNCTION carpoolvote.rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_exists(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE OR REPLACE FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	ride_request_row carpoolvote.rider%ROWTYPE;
	drive_offer_row carpoolvote.driver%ROWTYPE;
	match_row carpoolvote.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
	
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body   carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;

BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.rider r
	WHERE r."UUID" = a_UUID
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."RiderLastName", r."RiderPhone")
	)
	THEN
		return 'No Ride Request found for those parameters';
	END IF;

	return '';	
	
END  

$$;


ALTER FUNCTION carpoolvote.rider_exists(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_info(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE OR REPLACE FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	ride_request_row carpoolvote.rider%ROWTYPE;
	drive_offer_row carpoolvote.driver%ROWTYPE;
	match_row carpoolvote.match%ROWTYPE;
	v_step character varying(200);
	v_return_text character varying(200);
	
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body   carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
	r_row carpoolvote.rider%ROWTYPE;

BEGIN 

	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.rider r
	WHERE r."UUID" = a_UUID
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."RiderLastName", r."RiderPhone")
	)
	THEN
		-- return 'No Ride Request found for those parameters';
       RETURN row_to_json(r_row);
	END IF;

	-- return '';


    --BEGIN
        SELECT * INTO
            r_row
        FROM
            carpoolvote.rider
        WHERE
            "UUID" = a_uuid;

        RETURN row_to_json(r_row);
    --END	
	
END  

$$;


ALTER FUNCTION carpoolvote.rider_info(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;



--
-- Name: driver_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_cancel_drive_offer(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_confirm_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_confirmed_matches(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_exists(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_info(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_pause_match(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_proposed_matches(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_cancel_ride_request(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;

--
-- Name: rider_confirmed_match(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_exists(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_info(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: update_drive_offer_status(character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) TO carpool_admins;
GRANT ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) TO carpool_role;


--
-- Name: update_ride_request_status(character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION update_ride_request_status(a_uuid character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_ride_request_status(a_uuid character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION update_ride_request_status(a_uuid character varying) TO carpool_admins;
GRANT ALL ON FUNCTION update_ride_request_status(a_uuid character varying) TO carpool_web_role;
GRANT ALL ON FUNCTION update_ride_request_status(a_uuid character varying) TO carpool_role;


--carpoolvote.rider_update_match_details(UUID_driver, UUID_rider, rider’s phone number or rider’s lastname ?, rider_notes TEXT, OUT out_error_code INTEGER, OUT out_error_text TEXT))
CREATE OR REPLACE FUNCTION carpoolvote.rider_update_match_details(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
    confirmation_parameter character varying(255),
	a_rider_notes text,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
	AS
$BODY$

DECLARE                                                   
	v_step character varying(200); 
	v_return_text character varying(200);	
	
BEGIN 


	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';

		
	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.match m, carpoolvote.rider r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.uuid_rider = r."UUID"
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."RiderLastName", r."RiderPhone")
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'No Match can be confirmed with those parameters';
		RETURN;
	END IF;
	
	BEGIN
		UPDATE carpoolvote.match
		SET rider_notes = a_rider_notes
		WHERE
		uuid_driver = a_UUID_driver
		AND uuid_rider = a_UUID_rider;
	
		RETURN;
	
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Exception occurred during processing: driver_confirm_match,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;


    END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.rider_update_match_details(character varying, character varying, character varying, text,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_update_match_details(character varying, character varying, character varying, text,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_update_match_details(character varying, character varying, character varying, text,
	out integer, out text) TO carpool_role;


--carpoolvote.driver_update_match_details(UUID_driver, UUID_rider, driver’s phone number or rider’s lastname ?, driver_notes TEXT, OUT out_error_code INTEGER, OUT out_error_text TEXT))
CREATE OR REPLACE FUNCTION carpoolvote.driver_update_match_details(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
    confirmation_parameter character varying(255),
	a_driver_notes text,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
	AS
$BODY$

DECLARE                                                   
	v_step character varying(200); 
	v_return_text character varying(200);	
	
BEGIN 


	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';

		
	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.match m, carpoolvote.driver r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.uuid_driver = r."UUID"
	AND carpoolvote.validate_name_or_phone(confirmation_parameter, r."DriverLastName", r."DriverPhone")
	)
	THEN
		out_error_code := carpoolvote.f_INPUT_VAL_ERROR();
		out_error_text := 'No Match can be confirmed with those parameters';
		RETURN;
	END IF;
	
	BEGIN
		UPDATE carpoolvote.match
		SET driver_notes = a_driver_notes
		WHERE
		uuid_driver = a_UUID_driver
		AND uuid_rider = a_UUID_rider;
	
		RETURN;
	
	EXCEPTION WHEN OTHERS 
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Exception occurred during processing: driver_confirm_match,' || v_step || '(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;


    END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_update_match_details(character varying, character varying, character varying, text,
	out integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_update_match_details(character varying, character varying, character varying, text,
	out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_update_match_details(character varying, character varying, character varying, text,
	out integer, out text) TO carpool_role;


-- 
-- 
-- submit_new_user
-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 1  : ERROR - Input is disabled
-- 2  : ERROR - Input validation
CREATE OR REPLACE FUNCTION carpoolvote.submit_new_user(
    email character varying,
    username character varying,
    userpassword character varying,
    userIsAdmin boolean,
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$
DECLARE
	v_step character varying(200);
	a_ip inet;
BEGIN	
	
	out_uuid := '';
	out_error_code := 0;
	out_error_text := '';

-- validation steps

	BEGIN			
		out_uuid := carpoolvote.gen_random_uuid();
		
		INSERT INTO carpoolvote.tb_user(
		"UUID", email, username, password, is_admin)
		VALUES (
		out_uuid, email, username, userpassword, userIsAdmin
		);
			
		RETURN;
	EXCEPTION WHEN OTHERS
	THEN
		out_uuid := '';
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in submit_new_user, ' || v_step || ' (' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
	
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.submit_new_user(
    email character varying,
    username character varying,
    userpassword character varying,
    userIsAdmin boolean,
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_user(
    email character varying,
    username character varying,
    userpassword character varying,
    userIsAdmin boolean,
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_user(
    email character varying,
    username character varying,
    userpassword character varying,
    userIsAdmin boolean,
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) TO carpool_role;
	