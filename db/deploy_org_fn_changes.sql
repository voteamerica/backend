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
    character varying,out character varying, out integer, out text)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider(	character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying, character varying,
    character varying,out character varying, out integer, out text) TO carpool_web_role;
	
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider( character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying, character varying,
    character varying,out character varying, out integer, out text) TO carpool_role;


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
    character varying,out character varying, out integer, out text)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider(	character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying,
    character varying,out character varying, out integer, out text) TO carpool_web_role;
	
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider( character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying,
    character varying,out character varying, out integer, out text) TO carpool_role;
	

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
