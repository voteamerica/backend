-- actions by rider
--nov2016.rider_cancel_ride_request(UUID, phone number or lastname ?)
--nov2016.rider_cancel_confirmed_match(UUID_driver, UUID_rider, score, rider’s phone number or rider’s lastname ?)

-- actions by driver
--nov2016.driver_cancel_drive_offer(UUID, phone number or lastname ?)
--nov2016.driver_cancel_confirmed_match(UUID_driver, UUID_rider, driverr’s phone number or driver’s lastname ?)
--nov2016.driver_confirm_match(UUID_driver, UUID_rider, score, driver’s phone number or driver’s lastname ?)
--nov2016.driver_pause_match(UUID, phone number or lastname ?)

-- functions return character varying with explanatory text of error condition. Empty string if success


-- Common function to update state of ride request record

CREATE OR REPLACE FUNCTION nov2016.get_param_value(a_param_name character varying)
  RETURNS character varying AS
$BODY$
DECLARE

v_env nov2016.params.value%TYPE;

BEGIN

v_env := NULL;

BEGIN
	SELECT value INTO v_env FROM nov2016.params WHERE name=a_param_name;
EXCEPTION WHEN OTHERS
THEN
	v_env := NULL;
END;

RETURN v_env;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.get_param_value(character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.get_param_value(character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.get_param_value(character varying) TO carpool_role;


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
	
	v_subject nov2016.outgoing_email.subject%TYPE;                                                                            
	v_body nov2016.outgoing_email.body%TYPE;                                                                                  
	v_html_header nov2016.outgoing_email.body%TYPE;
	v_html_body   nov2016.outgoing_email.body%TYPE;
	v_html_footer nov2016.outgoing_email.body%TYPE;

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
		v_step := 'S0';
		SELECT * INTO ride_request_row
		FROM stage.websubmission_rider
		WHERE "UUID" = a_UUID;
	
		v_step := 'S1';
		FOR match_row IN SELECT * FROM nov2016.match
			WHERE uuid_rider = a_UUID
			AND state = 'MatchConfirmed'
		
		LOOP
		
			v_step := 'S2';
			SELECT * INTO drive_offer_row
			FROM stage.websubmission_driver
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
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>Hopefully you can help another rider in your area.</p>'
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO nov2016.outgoing_email (recipient, subject, body)
				VALUES (drive_offer_row."DriverEmail", 
				v_subject, 
				v_body);
			END IF;
			
			IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
			THEN
			
				v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by rider. No further action needed. \n'
					|| 'Rider : ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				v_body);
			END IF;

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
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
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
			
			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_body);
		END IF;
			
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Ride Request ' || ride_request_row."UUID"  || ' was canceled. No further action needed. \n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
		
			INSERT INTO nov2016.outgoing_sms (recipient, body)
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
	
	v_subject nov2016.outgoing_email.subject%TYPE;                                                                            
	v_body nov2016.outgoing_email.body%TYPE;                                                                                  
	v_html_header nov2016.outgoing_email.body%TYPE;
	v_html_body   nov2016.outgoing_email.body%TYPE;
	v_html_footer nov2016.outgoing_email.body%TYPE;

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
		
		SELECT * INTO ride_request_row
		FROM stage.websubmission_rider
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
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>Hopefully you can help another rider in your area.</p>'
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO nov2016.outgoing_email (recipient, subject, body)
				VALUES (drive_offer_row."DriverEmail", 
				v_subject, 
				v_body);
		END IF;
		
		IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by rider. No further action needed. \n'
					|| 'Rider : ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				v_body);
		END IF;
		


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
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>We will try to find another suitable driver.</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || nov2016.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_body);
			
		END IF;
			
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled. No further action needed. \n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
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
	
	v_subject nov2016.outgoing_email.subject%TYPE;                                                                            
	v_body nov2016.outgoing_email.body%TYPE;                                                                                  
	v_html_header nov2016.outgoing_email.body%TYPE;
	v_html_body   nov2016.outgoing_email.body%TYPE;
	v_html_footer nov2016.outgoing_email.body%TYPE;

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
		v_step := 'S0';
		SELECT * INTO drive_offer_row
		FROM stage.websubmission_driver
		WHERE "UUID" = a_UUID;	
	
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
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>We will try to find another suitable driver.</p>'
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || nov2016.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO nov2016.outgoing_email (recipient, subject, body)
				VALUES (ride_request_row."RiderEmail", 
				v_subject, 
				v_body);

			
			END IF;
			
			IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
			THEN
		
				v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by driver. No further action needed. \n'
					|| 'Driver : ' || drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
				VALUES (ride_request_row."RiderPhone", 
				v_body);
			END IF;

			

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


            INSERT INTO nov2016.outgoing_email (recipient, subject, body)                                             
            VALUES (drive_offer_row."DriverEmail", v_subject, v_body);                                                                 
			
		END IF;

		
		IF drive_offer_row."DriverPhone" IS NOT NULL
		THEN
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Drive Offer ' || drive_offer_row."UUID" ||  ' was canceled. No further action needed. \n'
					|| 'Pick-up ZIP : ' || drive_offer_row."DriverCollectionZIP" || '\n'
					|| 'Radius : ' || drive_offer_row."DriverCollectionRadius" || '\n'
					|| 'Drive Times : ' || replace(replace(replace(replace(replace(drive_offer_row."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-'); 
			
			INSERT INTO nov2016.outgoing_sms (recipient, body)
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
	
	v_subject nov2016.outgoing_email.subject%TYPE;                                                                            
	v_body nov2016.outgoing_email.body%TYPE;                                                                                  
	v_html_header nov2016.outgoing_email.body%TYPE;
	v_html_body   nov2016.outgoing_email.body%TYPE;
	v_html_footer nov2016.outgoing_email.body%TYPE;

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

		SELECT * INTO drive_offer_row
		FROM stage.websubmission_driver
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
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>Concerning this ride, no further action is needed from you.</p>'
			|| '<p>We will try to find another suitable driver.</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || nov2016.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_body);

		END IF;
		
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by driver. No further action needed. \n'
					|| 'Driver : ' ||  drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName"  || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
				VALUES (ride_request_row."RiderPhone", 
				v_body);
		END IF;
		
		
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
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>We hope you can still are still able to help another rider.</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If are no longer able to offer a ride, please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || nov2016.urlencode(drive_offer_row."DriverLastName") ||  '">cancel this Drive Offer</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (drive_offer_row."DriverEmail", 
			v_subject, 
			v_body);
		
		END IF;
		
		IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled. No further action needed. \n'
					|| 'Rider : ' ||  ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName"  || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
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
	
	v_subject nov2016.outgoing_email.subject%TYPE;                                                                            
	v_body nov2016.outgoing_email.body%TYPE;                                                                                  
	v_html_header nov2016.outgoing_email.body%TYPE;
	v_html_body   nov2016.outgoing_email.body%TYPE;
	v_html_footer nov2016.outgoing_email.body%TYPE;

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
		UPDATE nov2016.match
		SET state='MatchConfirmed'
		WHERE uuid_rider = a_UUID_rider
		AND uuid_driver = a_UUID_driver
		AND score = a_score;
	
		v_step := 'S2, ' || a_UUID_driver;
		v_return_text := nov2016.update_drive_offer_state(a_UUID_driver);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
	
		v_step := 'S3, ' || a_UUID_rider;
		v_return_text := nov2016.update_ride_request_state(a_UUID_rider);
		IF  v_return_text != ''
		THEN
			v_step := v_step || ' ' || v_return_text;
			RAISE NOTICE '%', v_return_text;
			RAISE EXCEPTION '%', v_return_text;
		END IF;
		
		v_step := 'S3';
		SELECT * INTO ride_request_row
		FROM stage.websubmission_rider
		WHERE "UUID" = a_UUID_rider;	
		
	
		v_step := 'S4';
		-- send confirmation notice to driver
		SELECT * INTO drive_offer_row
		FROM stage.websubmission_driver
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
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || ride_request_row."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || ride_request_row."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>If you can no longer drive ' || drive_offer_row."DriverFirstName" || ', please let us know and '
			|| '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-driver-match?UUID_driver=' || a_UUID_driver 
			|| '&UUID_rider=' || a_UUID_rider 
			|| '&Score=' || a_score 
			|| '&DriverPhone=' || nov2016.urlencode(drive_offer_row."DriverLastName" ) || '">cancel this ride match only</a></p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || nov2016.urlencode(drive_offer_row."DriverLastName") ||  '">Cancel this Drive Offer</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (drive_offer_row."DriverEmail", 
			v_subject, 
			v_body);
		END IF;
		
		v_step := 'S6';
		IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Match is confirmed. No further action needed. \n'
					|| 'Rider : ' ||  ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName"  || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
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
			|| 'will get in touch to arrange the details of the ride.</p>'
			|| '<p>If you DO NOT hear from ' || drive_offer_row."DriverFirstName" || ', please feel free to reach out :<br/>'
			|| CASE WHEN drive_offer_row."DriverEmail" IS NOT NULL THEN '- ' || CASE WHEN coalesce(drive_offer_row."DriverPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || 'Email: ' || drive_offer_row."DriverEmail"  ELSE ' ' END || '<br/>'
			|| CASE WHEN drive_offer_row."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(drive_offer_row."DriverPreferredContact" LIKE '%Phone%',false) THEN '(*)' else ' ' END || 'Phone: ' || drive_offer_row."DriverPhone"  ELSE ' ' END || '<br/>'
			|| CASE WHEN drive_offer_row."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(drive_offer_row."DriverPreferredContact" LIKE '%SMS%',false) THEN '(*)' else ' ' END || 'SMS/Text: ' || drive_offer_row."DriverPhone"  ELSE ' ' END || '<br/>'
			|| '(*) = Preferred Method</p>'
			|| '<p>If you would prefer to have a different driver, please let us know, and '
			|| '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-rider-match?UUID_driver=' || a_UUID_driver 
			|| '&UUID_rider=' || a_UUID_rider 
			|| '&Score=' || a_score 
			|| '&RiderPhone=' || nov2016.urlencode( ride_request_row."RiderLastName") || '">cancel this ride match only</a></p>'   -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?uuid=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || ride_request_row."UUID" || '&RiderPhone=' || nov2016.urlencode(ride_request_row."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
		
			v_body := v_html_header || v_html_body || v_html_footer;
		
			INSERT INTO nov2016.outgoing_email (recipient, subject, body)
			VALUES (ride_request_row."RiderEmail", 
			v_subject, 
			v_html_body);
		END IF;
		
		v_step := 'S8';
		IF ride_request_row."RiderPhone" IS NOT NULL AND (position('SMS' in ride_request_row."RiderPreferredContact") > 0)
		THEN
			v_body := 'From CarpoolVote.com\n'
					|| 'Match is confirmed by driver. No further action needed. \n'
					|| 'Driver : ' ||  drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
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
ALTER FUNCTION nov2016.driver_confirm_match(character varying, character varying, smallint, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirm_match(character varying, character varying, smallint, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirm_match(character varying, character varying, smallint, character varying) TO carpool_role;


--------------------------------------------------------
-- USER STORY 016 - DRIVER pauses match
--------------------------------------------------------
CREATE OR REPLACE FUNCTION nov2016.driver_pause_match(
    a_UUID character varying(50),
    confirmation_parameter character varying(255))
  RETURNS character varying AS
$BODY$

DECLARE                                                   
	drive_offer_row stage.websubmission_driver%ROWTYPE;
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
		UPDATE stage.websubmission_driver
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
ALTER FUNCTION nov2016.driver_pause_match(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_pause_match(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_pause_match(character varying, character varying) TO carpool_role;
