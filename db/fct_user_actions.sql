-- actions by rider
--carpoolvote.rider_cancel_ride_request(UUID, phone number or lastname ?)
--carpoolvote.rider_cancel_confirmed_match(UUID_driver, UUID_rider, score, rider’s phone number or rider’s lastname ?)

-- actions by driver
--carpoolvote.driver_cancel_drive_offer(UUID, phone number or lastname ?)
--carpoolvote.driver_cancel_confirmed_match(UUID_driver, UUID_rider, driverr’s phone number or driver’s lastname ?)
--carpoolvote.driver_confirm_match(UUID_driver, UUID_rider, score, driver’s phone number or driver’s lastname ?)
--carpoolvote.driver_pause_match(UUID, phone number or lastname ?)

-- functions return character varying with explanatory text of error condition. Empty string if success



-- Common function to update status of ride request record

SET search_path = carpoolvote, pg_catalog;


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
	OUT out_uuid character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$
DECLARE
	v_step character varying(200);
BEGIN	

	IF  LOWER(COALESCE(carpoolvote.get_param_value('input.rider.enabled'), 'false')) = LOWER('false')
	THEN
	    out_uuid := '';
		out_error_code := 1;
		out_error_text := 'Submission of new Rider is disabled.';
		RETURN;
	END IF;
	
	

	BEGIN
	
		out_uuid := carpoolvote.gen_random_uuid();
		
		IF (a_IPAddress is null) or (length(a_IPAddress) = 0) THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid IPAddress';
			RETURN;
		END IF;
		
		IF (a_AvailableRideTimesLocal is null) or (length(a_AvailableRideTimesLocal) = 0) THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid AvailableRideTimesLocal';
			RETURN;
		END IF;
		
		IF (a_TotalPartySize is null) or (a_TotalPartySize <= 0) THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid TotalPartySize';
			RETURN;
		END IF;
		
		IF (a_RiderPreferredContact is null) or (a_RiderPreferredContact != 'SMS' and a_RiderPreferredContact != 'Email' and a_RiderPreferredContact != 'Phone')
		THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid RiderPreferredContact (SMS/Email/Phone)';
			RETURN;
		END IF;
		

		INSERT INTO carpoolvote.rider(
		"UUID", "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail", "RiderPhone", "RiderCollectionZIP",
		"RiderDropOffZIP", "AvailableRideTimesLocal", "TotalPartySize", "TwoWayTripNeeded", "RiderIsVulnerable",
		"RiderWillNotTalkPolitics", "PleaseStayInTouch", "NeedWheelchair", "RiderPreferredContact",
		"RiderAccommodationNotes", "RiderLegalConsent", "RiderWillBeSafe", "RiderCollectionAddress", "RiderDestinationAddress")
		VALUES (
		out_uuid, a_IPAddress, a_RiderFirstName, a_RiderLastName, a_RiderEmail, a_RiderPhone, a_RiderCollectionZIP,
		a_RiderDropOffZIP, a_AvailableRideTimesLocal, a_TotalPartySize, a_TwoWayTripNeeded, a_RiderIsVulnerable,
		a_RiderWillNotTalkPolitics, a_PleaseStayInTouch, a_NeedWheelchair, a_RiderPreferredContact,
		a_RiderAccommodationNotes, a_RiderLegalConsent, a_RiderWillBeSafe, a_RiderCollectionAddress, a_RiderDestinationAddress);
	
		out_error_code := 0;
		out_error_text := '';
	
	
		RETURN;
	EXCEPTION WHEN OTHERS
	THEN

		out_error_code := -1;
		out_error_text := 'Unexpected exception (' || SQLSTATE || ')' || SQLERRM;
	
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
    character varying, character varying, boolean, boolean, character varying,
    character varying,out character varying, out integer, out text)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_rider(	character varying,
    character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, integer, boolean, boolean, boolean, boolean, boolean,
    character varying, character varying, boolean, boolean, character varying,
    character varying,out character varying, out integer, out text) TO carpool_web;
	
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
BEGIN	

	IF  LOWER(COALESCE(carpoolvote.get_param_value('input.driver.enabled'), 'false')) = LOWER('false')
	THEN
	    out_uuid := '';
		out_error_code := 1;
		out_error_text := 'Submission of new Driver is disabled.';
		RETURN;
	END IF;
	
	

	BEGIN
	
		out_uuid := carpoolvote.gen_random_uuid();
		
		IF (a_IPAddress is null) or (length(a_IPAddress) = 0) THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid IPAddress';
			RETURN;
		END IF;
		
		IF (a_AvailableDriveTimesLocal is null) or (length(a_AvailableDriveTimesLocal) = 0) THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid AvailableDriveTimesLocal';
			RETURN;
		END IF;
		
		IF (a_DriverCollectionRadius is null) or (a_DriverCollectionRadius <= 0) THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid DriverCollectionRadius';
			RETURN;
		END IF;

		IF (a_SeatCount is null) or (a_SeatCount <= 0) THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid SeatCount';
			RETURN;
		END IF;
		
		IF (a_DriverPreferredContact is null) or (a_DriverPreferredContact != 'SMS' and a_DriverPreferredContact != 'Email' and a_DriverPreferredContact != 'Phone')
		THEN
			out_uuid := '';
			out_error_code := 2;
			out_error_text := 'Invalid DriverPreferredContact (SMS/Email/Phone)';
			RETURN;
		END IF;
		

		INSERT INTO carpoolvote.driver(
		"UUID", "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", "AvailableDriveTimesLocal", 
		"DriverCanLoadRiderWithWheelchair", "SeatCount", "DriverLicenseNumber", 
		"DriverFirstName", "DriverLastName", "DriverEmail", "DriverPhone",
		"DrivingOnBehalfOfOrganization", "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails",
		"DriverWillNotTalkPolitics", "PleaseStayInTouch", "DriverPreferredContact", "DriverWillTakeCare")
		VALUES (
		out_uuid, 
		a_IPAddress, a_DriverCollectionZIP, a_DriverCollectionRadius, a_AvailableDriveTimesLocal, 
		a_DriverCanLoadRiderWithWheelchair, a_SeatCount, a_DriverLicenseNumber, 
		a_DriverFirstName, a_DriverLastName, a_DriverEmail, a_DriverPhone,
		a_DrivingOnBehalfOfOrganization, a_DrivingOBOOrganizationName, a_RidersCanSeeDriverDetails,
		a_DriverWillNotTalkPolitics, a_PleaseStayInTouch, a_DriverPreferredContact, a_DriverWillTakeCare
		);
	
		out_error_code := 0;
		out_error_text := '';
	
		RETURN;
	EXCEPTION WHEN OTHERS
	THEN

		out_error_code := -1;
		out_error_text := 'Unexpected exception (' || SQLSTATE || ')' || SQLERRM;
	
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
	OUT character varying, OUT INTEGER, OUT TEXT) TO carpool_web;
	
GRANT EXECUTE ON FUNCTION carpoolvote.submit_new_driver( 
character varying, character varying, integer, character varying,
	boolean, integer, character varying, character varying, character varying,
	character varying, character varying, boolean, character varying,
	boolean, boolean, boolean, character varying, boolean,
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
		WHERE "UUID" = a_UUID;
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
		WHERE "UUID" = a_UUID;
	
	ELSE               -- default, is Pending
		v_step := 'S4';
		UPDATE carpoolvote.rider
		SET status='Pending'
		WHERE "UUID" = a_UUID;
		
	END IF;
		
	RETURN '';
	
	EXCEPTION WHEN OTHERS
	THEN
		RAISE NOTICE 'Exception occurred during processing: update_ride_request_status,%', v_step;
		return 'Exception occurred during processing: update_ride_request_status,' || v_step;
	END;
			
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.update_ride_request_status(character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.update_ride_request_status(character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.update_ride_request_status(character varying) TO carpool_role;


-- Common function to update status of drive offer record
CREATE OR REPLACE FUNCTION carpoolvote.update_drive_offer_status(
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
		WHERE uuid_driver = a_UUID
		AND status='MatchConfirmed'
	)
	THEN	
		v_step := 'S2';
		UPDATE carpoolvote.driver
		SET status='MatchConfirmed'
		WHERE "UUID" = a_UUID;
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
		WHERE "UUID" = a_UUID;
	
	ELSE               -- default, is Pending
		v_step := 'S4';
		UPDATE carpoolvote.driver
		SET status='Pending'
		WHERE "UUID" = a_UUID;
		
	END IF;
		
	RETURN '';
	
	EXCEPTION WHEN OTHERS
	THEN
		RAISE NOTICE 'Exception occurred during processing: update_drive_offer_status,%', v_step;
		return 'Exception occurred during processing: update_drive_offer_status,' || v_step;
	END;
			
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.update_drive_offer_status(character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.update_drive_offer_status(character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.update_drive_offer_status(character varying) TO carpool_role;


--------------------------------------------------------
-- USER STORY 003 - RIDER cancels ride request
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.rider_cancel_ride_request(
    a_UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

	v_html_header := '<!doctype html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'
		|| '<html>' 
		|| '<head>'
		|| '<meta http-equiv="content-type" content="text/html; charset=UTF-8">'
		|| '<style type="text/css">'
		|| '.evenRow {'
		|| '  font-family:Monospace;'
		|| '  border-bottom: black thin;'
		|| '  border-top: black thin;'
		|| '  border-right: black thin;'
		|| '  border-left: black thin;'	
		|| '  border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #F0F0F0'
		|| '}'
		|| '.oddRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #E0E0E0'
		|| '}'
		|| '.warnRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #FF9933'
		|| '}'
		|| '</style>'
		|| '</head>'; 

	v_html_footer := '</html>';	


	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.rider r
	WHERE r."UUID" = a_UUID
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
		FROM carpoolvote.rider
		WHERE "UUID" = a_UUID;
	
		v_step := 'S1';
		FOR match_row IN SELECT * FROM carpoolvote.match
			WHERE uuid_rider = a_UUID
			AND status = 'MatchConfirmed'
		
		LOOP
		
			v_step := 'S2';
			SELECT * INTO drive_offer_row
			FROM carpoolvote.driver
			WHERE "UUID" = match_row.uuid_driver;
		
			v_step := 'S3';   -- Cancellation Notification to confirmed drivers
			IF drive_offer_row."DriverEmail" IS NOT NULL
			THEN
				
				-- Cancellation notice to driver
				v_subject := 'Confirmed Ride Cancellation Notice   --- [' || drive_offer_row."UUID" || ']';
				v_html_body := '<body>'
				|| '<p>Dear ' || drive_offer_row."DriverFirstName" ||  ' ' || drive_offer_row."DriverLastName" || ', <p>' 
				|| '<p>' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" 
				|| ' no longer needs a ride. </p>'
				|| '<p>These were the ride details: </p>'
				|| '<p><table>'
				|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
					replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">'  || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') ||  ride_request_row."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>Hopefully you can help another rider in your area.</p>'
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=driver&uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
				VALUES (drive_offer_row."DriverEmail", 
				v_subject, 
				v_body);
			END IF;
			
			IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
			THEN
			
				v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Confirmed Ride was canceled by rider. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Rider : ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : '  ||  COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				v_body);
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
		WHERE uuid_rider = a_UUID;
		
		v_step := 'S7';
		-- Update Ride Request to Canceled
		UPDATE carpoolvote.rider
		SET status='Canceled'
		WHERE "UUID" = a_UUID;
		
		
		-- Send cancellation notice to rider
		IF ride_request_row."RiderEmail" IS NOT NULL
		THEN
			v_subject := 'Ride Request Cancellation Notice   --- [' || ride_request_row."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || ', </p>'
			|| '<p>We have processed your request to cancel a ride request. If a ride had already been confirmed, the driver has been notified.</p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;
			
			INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_body);
		END IF;
			
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Ride Request ' || ride_request_row."UUID"  || ' was canceled. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
		
			INSERT INTO carpoolvote.outgoing_sms (recipient, body)
			VALUES (ride_request_row."RiderPhone", 
			v_body);
		END IF;
		
		return '';
    
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: rider_cancel_ride_request,' || v_step;
	END;
	
END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.rider_cancel_ride_request(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_ride_request(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_ride_request(character varying, character varying) TO carpool_role;



--------------------------------------------------------
-- USER STORY 004 - RIDER cancels a confirmed match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.rider_cancel_confirmed_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
	a_score smallint,
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

	v_html_header := '<!doctype html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'
		|| '<html>' 
		|| '<head>'
		|| '<meta http-equiv="content-type" content="text/html; charset=UTF-8">'
		|| '<style type="text/css">'
		|| '.evenRow {'
		|| '  font-family:Monospace;'
		|| '  border-bottom: black thin;'
		|| '  border-top: black thin;'
		|| '  border-right: black thin;'
		|| '  border-left: black thin;'	
		|| '  border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #F0F0F0'
		|| '}'
		|| '.oddRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #E0E0E0'
		|| '}'
		|| '.warnRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #FF9933'
		|| '}'
		|| '</style>'
		|| '</head>'; 

	v_html_footer := '</html>';	


	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.match m, carpoolvote.rider r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.score = a_score
	AND m.status = 'MatchConfirmed'   -- We can cancel only a Confirmed match
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
		UPDATE carpoolvote.match
		SET status='Canceled'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver
		AND score = a_score;
	
		v_step := 'S1';
		SELECT * INTO drive_offer_row
		FROM carpoolvote.driver
		WHERE "UUID" = a_UUID_driver;	
		
		SELECT * INTO ride_request_row
		FROM carpoolvote.rider
		WHERE "UUID" = a_UUID_rider;	

		
		v_step := 'S2';
		IF drive_offer_row."DriverEmail" IS NOT NULL
		THEN
			-- Cancellation notice to driver
				v_subject := 'Confirmed Ride Cancellation Notice   --- [' || drive_offer_row."UUID" || ']';
				v_html_body := '<body>'
				|| '<p>Dear ' || drive_offer_row."DriverFirstName" ||  ' ' || drive_offer_row."DriverLastName" || ', <p>' 
				|| '<p>' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" 
				|| ' no longer needs a ride.</p>'
				|| '<p>These were the ride details: </p>'
				|| '<p><table>'
				|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
					replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>Hopefully you can help another rider in your area.</p>'
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=driver&uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
				VALUES (drive_offer_row."DriverEmail", 
				v_subject, 
				v_body);
		END IF;
		
		IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Confirmed Ride was canceled by rider. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Rider : ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				v_body);
		END IF;
		


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
		
		IF ride_request_row."RiderEmail" IS NOT NULL
		THEN
			-- Cancellation notice to rider
			v_subject := 'Confirmed Ride Cancellation Notice   --- [' || ride_request_row."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || ', </p>'
			|| '<p>We have processed your request to cancel a confirmed ride with ' || drive_offer_row."DriverFirstName" ||  ' ' || drive_offer_row."DriverLastName" || '</p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>We will try to find another suitable driver.</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=rider&uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || carpoolvote.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_body);
			
		END IF;
			
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Confirmed Ride was canceled. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (ride_request_row."RiderPhone", 
				v_body);
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
ALTER FUNCTION carpoolvote.rider_cancel_confirmed_match(character varying, character varying, smallint, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_role;

--------------------------------------------------------
-- USER STORY 013 - DRIVER cancels driver offer
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_cancel_drive_offer(
    a_UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

	v_html_header := '<!doctype html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'
		|| '<html>' 
		|| '<head>'
		|| '<meta http-equiv="content-type" content="text/html; charset=UTF-8">'
		|| '<style type="text/css">'
		|| '.evenRow {'
		|| '  font-family:Monospace;'
		|| '  border-bottom: black thin;'
		|| '  border-top: black thin;'
		|| '  border-right: black thin;'
		|| '  border-left: black thin;'	
		|| '  border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #F0F0F0'
		|| '}'
		|| '.oddRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #E0E0E0'
		|| '}'
		|| '.warnRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #FF9933'
		|| '}'
		|| '</style>'
		|| '</head>'; 

	v_html_footer := '</html>';	


	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.driver r
	WHERE r."UUID" = a_UUID
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Drive Offer found for those parameters';
	END IF;

	BEGIN
		v_step := 'S0';
		SELECT * INTO drive_offer_row
		FROM carpoolvote.driver
		WHERE "UUID" = a_UUID;	
	
		v_step := 'S1';
		FOR match_row IN SELECT * FROM carpoolvote.match
			WHERE uuid_driver = a_UUID
			AND status = 'MatchConfirmed'
		
		LOOP
		
			v_step := 'S2';
			SELECT * INTO ride_request_row
			FROM carpoolvote.rider
			WHERE "UUID" = match_row.uuid_rider;	
		
			v_step := 'S3';
			IF ride_request_row."RiderEmail" IS NOT NULL
			THEN

				-- Cancellation notice to rider
				v_subject := 'Confirmed Ride Cancellation Notice   --- [' || drive_offer_row."UUID" || ']';
				v_html_body := '<body>'
				|| '<p>Dear ' || ride_request_row."RiderFirstName" ||  ' ' || ride_request_row."RiderLastName" || ', <p>' 
				|| '<p>Your driver ' || drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" 
				|| ' has canceled this ride. </p>'
				|| '<p>These were the ride details: </p>'
				|| '<p><table>'
				|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
					replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>We will try to find another suitable driver.</p>'
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=rider&uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || carpoolvote.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
				VALUES (ride_request_row."RiderEmail", 
				v_subject, 
				v_body);

			
			END IF;
			
			IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
			THEN
		
				v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Confirmed Ride was canceled by driver. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Driver : ' || drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (ride_request_row."RiderPhone", 
				v_body);
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


		IF drive_offer_row."DriverEmail" IS NOT NULL
		THEN
			
			v_subject := 'Drive Offer is canceled   --- [' || drive_offer_row."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || drive_offer_row."DriverFirstName" ||  ' ' || drive_offer_row."DriverLastName" || ', <p>' 
			|| '<p>We have received your request to cancel your drive offer.</p>'
			|| 'These were the details of the offer:<br/>'
			|| '<table>'
			|| '<tr><td class="evenRow">Pick-up ZIP</td><td class="evenRow">' || drive_offer_row."DriverCollectionZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Radius</td><td class="oddRow">' || drive_offer_row."DriverCollectionRadius" || ' miles</td></tr>'
			|| '<tr><td class="evenRow">Drive Times</td><td class="evenRow">' || replace(replace(replace(replace(replace(drive_offer_row."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Seats</td><td class="oddRow">' || drive_offer_row."SeatCount" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessible</td><td class="evenRow">' || CASE WHEN drive_offer_row."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || drive_offer_row."DriverPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || drive_offer_row."DriverEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is necessary.</p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;


            INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)                                             
            VALUES (drive_offer_row."DriverEmail", v_subject, v_body);                                                                 
			
		END IF;

		
		IF drive_offer_row."DriverPhone" IS NOT NULL
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Drive Offer ' || drive_offer_row."UUID" ||  ' was canceled. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up ZIP : ' || drive_offer_row."DriverCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Radius : ' || drive_offer_row."DriverCollectionRadius" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Drive Times : ' || replace(replace(replace(replace(replace(drive_offer_row."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-'); 
			
			INSERT INTO carpoolvote.outgoing_sms (recipient, body)
			VALUES (drive_offer_row."DriverPhone", 
			v_body);
		END IF;
		
		
		return '';
    	
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: driver_cancel_drive_offer,' || v_step;
	END;

END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_cancel_drive_offer(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_drive_offer(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_drive_offer(character varying, character varying) TO carpool_role;

--------------------------------------------------------
-- USER STORY 014 - DRIVER cancels confirmed match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_cancel_confirmed_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
	a_score smallint,
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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

	v_html_header := '<!doctype html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'
		|| '<html>' 
		|| '<head>'
		|| '<meta http-equiv="content-type" content="text/html; charset=UTF-8">'
		|| '<style type="text/css">'
		|| '.evenRow {'
		|| '  font-family:Monospace;'
		|| '  border-bottom: black thin;'
		|| '  border-top: black thin;'
		|| '  border-right: black thin;'
		|| '  border-left: black thin;'	
		|| '  border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #F0F0F0'
		|| '}'
		|| '.oddRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #E0E0E0'
		|| '}'
		|| '.warnRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #FF9933'
		|| '}'
		|| '</style>'
		|| '</head>'; 

	v_html_footer := '</html>';	


	-- input validation
	IF NOT EXISTS (
	SELECT 1 
	FROM carpoolvote.match m, carpoolvote.driver r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.status = 'MatchConfirmed'   -- We can confirmed only a 
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
		UPDATE carpoolvote.match
		SET status='Canceled'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver
		AND score = a_score;
	
		v_step := 'S1';
		SELECT * INTO ride_request_row
		FROM carpoolvote.rider
		WHERE "UUID" = a_UUID_rider;	

		SELECT * INTO drive_offer_row
		FROM carpoolvote.driver
		WHERE "UUID" = a_UUID_driver;	

		
		v_step := 'S2';
		-- send cancellation notice to rider
		IF ride_request_row."RiderEmail" IS NOT NULL
		THEN
			-- Cancellation notice to rider
			v_subject := 'Confirmed Ride Cancellation Notice   --- [' || ride_request_row."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || ride_request_row."RiderFirstName" ||  ' ' || ride_request_row."RiderLastName" || ', <p>' 
			|| '<p>Your driver ' || drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" 
			|| ' has canceled this ride. </p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>Concerning this ride, no further action is needed from you.</p>'
			|| '<p>We will try to find another suitable driver.</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=rider&uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || carpoolvote.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_body);

		END IF;
		
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Confirmed Ride was canceled by driver. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Driver : ' ||  drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName"  || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (ride_request_row."RiderPhone", 
				v_body);
		END IF;
		
		
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

		IF drive_offer_row."DriverEmail" IS NOT NULL
		THEN

			v_subject := 'Confirmed Ride Cancellation Notice   --- [' || ride_request_row."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || drive_offer_row."DriverFirstName" ||  ' ' || drive_offer_row."DriverLastName" ||  ', </p>'
			|| '<p>We have processed your request to cancel a confirmed ride with ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || '</p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>We hope you can still are still able to help another rider.</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=driver&uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If are no longer able to offer a ride, please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || carpoolvote.urlencode(drive_offer_row."DriverLastName") ||  '">cancel this Drive Offer</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
			VALUES (drive_offer_row."DriverEmail", 
			v_subject, 
			v_body);
		
		END IF;
		
		IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Confirmed Ride was canceled. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Rider : ' ||  ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName"  || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				v_body);
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
ALTER FUNCTION carpoolvote.driver_cancel_confirmed_match(character varying, character varying, smallint, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_cancel_confirmed_match(character varying, character varying, smallint, character varying) TO carpool_role;

--------------------------------------------------------
-- USER STORY 015 - DRIVER confirms match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_confirm_match(
    a_UUID_driver character varying(50),
	a_UUID_rider character varying(50),
	a_score smallint,
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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
	FROM carpoolvote.match m, carpoolvote.driver r
	WHERE m.uuid_driver = a_UUID_driver
	AND m.uuid_rider = a_UUID_rider
	AND m.score = a_score
	AND m.status = 'MatchProposed'   -- We can confirmed only a 
	AND m.uuid_driver = r."UUID"
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Match can be confirmed with those parameters';
	END IF;

	v_html_header := '<!doctype html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'
		|| '<html>' 
		|| '<head>'
		|| '<meta http-equiv="content-type" content="text/html; charset=UTF-8">'
		|| '<style type="text/css">'
		|| '.evenRow {'
		|| '  font-family:Monospace;'
		|| '  border-bottom: black thin;'
		|| '  border-top: black thin;'
		|| '  border-right: black thin;'
		|| '  border-left: black thin;'	
		|| '  border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #F0F0F0'
		|| '}'
		|| '.oddRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #E0E0E0'
		|| '}'
		|| '.warnRow {'
		|| '  font-family:Monospace;'
		|| '	border-bottom: black thin;'
		|| '	border-top: black thin;'
		|| '	border-right: black thin;'
		|| '	border-left: black thin;'	
		|| '	border-collapse: collapse;'
		|| '  margin: 0.4em;'
		|| '  background-color: #FF9933'
		|| '}'
		|| '</style>'
		|| '</head>'; 

		v_html_footer := '</html>';	

	
	BEGIN
		v_step := 'S1';
		UPDATE carpoolvote.match
		SET status='MatchConfirmed'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver
		AND score = a_score;
	
		v_step := 'S2, ' || a_UUID_driver;
		v_return_text := carpoolvote.update_drive_offer_status(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
	
		v_step := 'S3, ' || a_UUID_rider;
		v_return_text := carpoolvote.update_ride_request_status(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_return_text;
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
		IF drive_offer_row."DriverEmail" IS NOT NULL
		THEN
			-- confirmation notice to driver
			v_subject := 'Contact details for accepted ride   --- [' || drive_offer_row."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || drive_offer_row."DriverFirstName" ||  ' ' || drive_offer_row."DriverLastName" || ', <p>' 
			|| '<p>You have accepted a proposed match for a rider - THANK YOU!</p>'
			|| '<p>' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" 
			|| ' is now waiting for you to get in touch to arrange the details of the ride.</p>'
			|| '<p>Please contact the rider as soon as possible via <br/>'
			|| CASE WHEN ride_request_row."RiderEmail" IS NOT NULL THEN '- ' || CASE WHEN coalesce(ride_request_row."RiderPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || 'Email: ' || ride_request_row."RiderEmail"  ELSE ' ' END || '<br/>'
			|| CASE WHEN ride_request_row."RiderPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(ride_request_row."RiderPreferredContact" LIKE '%Phone%',false) THEN '(*)' else ' ' END || 'Phone: ' || ride_request_row."RiderPhone"  ELSE ' ' END || '<br/>'
			|| CASE WHEN ride_request_row."RiderPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(ride_request_row."RiderPreferredContact" LIKE '%SMS%',false) THEN '(*)' else ' ' END || 'SMS/Text: ' || ride_request_row."RiderPhone"  ELSE ' ' END || '<br/>'
			|| '(*) = Preferred Method</p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>If you can no longer drive ' || drive_offer_row."DriverFirstName" || ', please let us know and '
			|| '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-driver-match?UUID_driver=' || a_UUID_driver 
			|| '&UUID_rider=' || a_UUID_rider 
			|| '&Score=' || a_score 
			|| '&DriverPhone=' || carpoolvote.urlencode(drive_offer_row."DriverLastName" ) || '">cancel this ride match only</a></p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=driver&uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || carpoolvote.urlencode(drive_offer_row."DriverLastName") ||  '">Cancel this Drive Offer</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
			VALUES (drive_offer_row."DriverEmail", 
			v_subject, 
			v_body);
		END IF;
		
		v_step := 'S6';
		IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Match is confirmed. No further action needed.' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Rider : ' ||  ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName"  || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				v_body);
		END IF;		



		v_step := 'S7';
		IF ride_request_row."RiderEmail" IS NOT NULL
		THEN
		
		    -- notification to the rider
			v_subject := 'You have been matched with a driver!   --- [' || ride_request_row."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || ride_request_row."RiderFirstName" ||  ' ' || ride_request_row."RiderLastName" || ', <p>' 
			|| '<p>Great news - a driver has accepted your request for a ride!</p>'
			|| '<p>' || drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" 
			|| ' will get in touch to arrange the details of the ride.</p>'
			|| '<p>If you DO NOT hear from ' || drive_offer_row."DriverFirstName" || ', please feel free to reach out :<br/>'
			|| CASE WHEN drive_offer_row."DriverEmail" IS NOT NULL THEN '- ' || CASE WHEN coalesce(drive_offer_row."DriverPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || 'Email: ' || drive_offer_row."DriverEmail"  ELSE ' ' END || '<br/>'
			|| CASE WHEN drive_offer_row."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(drive_offer_row."DriverPreferredContact" LIKE '%Phone%',false) THEN '(*)' else ' ' END || 'Phone: ' || drive_offer_row."DriverPhone"  ELSE ' ' END || '<br/>'
			|| CASE WHEN drive_offer_row."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(drive_offer_row."DriverPreferredContact" LIKE '%SMS%',false) THEN '(*)' else ' ' END || 'SMS/Text: ' || drive_offer_row."DriverPhone"  ELSE ' ' END || '<br/>'
			|| '(*) = Preferred Method</p>'
			|| '<p>If you would prefer to have a different driver, please let us know, and '
			|| '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-rider-match?UUID_driver=' || a_UUID_driver 
			|| '&UUID_rider=' || a_UUID_rider 
			|| '&Score=' || a_score 
			|| '&RiderPhone=' || carpoolvote.urlencode( ride_request_row."RiderLastName") || '">cancel this ride match only</a></p>'   -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=rider&uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || carpoolvote.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
		
			v_body := v_html_header || v_html_body || v_html_footer;
		
			INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_html_body);
		END IF;
		
		v_step := 'S8';
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
			v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Match is confirmed by driver. No further action needed.'|| ' ' || carpoolvote.urlencode(chr(10))
					|| ' Driver : ' ||  drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" || ' ' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up location : ' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || ' ' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Destination : ' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || ' ' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || ride_request_row."TotalPartySize" || ' ' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (ride_request_row."RiderPhone", 
				v_body);
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
ALTER FUNCTION carpoolvote.driver_confirm_match(character varying, character varying, smallint, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirm_match(character varying, character varying, smallint, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirm_match(character varying, character varying, smallint, character varying) TO carpool_role;


--------------------------------------------------------
-- USER STORY 016 - DRIVER pauses match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.driver_pause_match(
    a_UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

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
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	)
	THEN
		return 'No Drive Offer found for those parameters';
	END IF;

	BEGIN
		v_step := 'S1';
		UPDATE carpoolvote.driver
			SET "ReadyToMatch" = False
			WHERE "UUID" = a_UUID;
			
		return '';
	
	EXCEPTION WHEN OTHERS 
	THEN
		RETURN 'Exception occurred during processing: driver_pause_match,' || v_step;
	END;


    END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_pause_match(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_pause_match(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_pause_match(character varying, character varying) TO carpool_role;
