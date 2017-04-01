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
-- Name: carpoolvote; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA carpoolvote;


ALTER SCHEMA carpoolvote OWNER TO postgres;

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
-- Name: driver_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) RETURNS character varying
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
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
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by driver. No further action needed. \n'
					|| 'Driver : ' ||  drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName"  || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
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
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled. No further action needed. \n'
					|| 'Rider : ' ||  ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName"  || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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

$$;


ALTER FUNCTION carpoolvote.driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_cancel_drive_offer(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
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
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
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
		
				v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by driver. No further action needed. \n'
					|| 'Driver : ' || drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Drive Offer ' || drive_offer_row."UUID" ||  ' was canceled. No further action needed. \n'
					|| 'Pick-up ZIP : ' || drive_offer_row."DriverCollectionZIP" || '\n'
					|| 'Radius : ' || drive_offer_row."DriverCollectionRadius" || '\n'
					|| 'Drive Times : ' || replace(replace(replace(replace(replace(drive_offer_row."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-'); 
			
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

$$;


ALTER FUNCTION carpoolvote.driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_confirm_match(character varying, character varying, smallint, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) RETURNS character varying
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
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || ride_request_row."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || ride_request_row."RiderDropOffZIP" || '</td></tr>'
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" 
			|| '&UUID_rider=' || a_UUID_rider 
			|| '&Score=' || a_score 
			|| '">Self-Service Portal</a></p>'
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
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Match is confirmed. No further action needed. \n'
					|| 'Rider : ' ||  ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName"  || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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
			|| 'will get in touch to arrange the details of the ride.</p>'
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" 
			|| '&UUID_driver=' || a_UUID_driver 
			|| '&Score=' || a_score 
			|| '">Self-Service Portal</a></p>'
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
			v_body := 'From CarpoolVote.com\n'
					|| 'Match is confirmed by driver. No further action needed. \n'
					|| 'Driver : ' ||  drive_offer_row."DriverFirstName" || ' ' || drive_offer_row."DriverLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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

$$;


ALTER FUNCTION carpoolvote.driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_confirmed_matches(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) RETURNS SETOF json
    LANGUAGE sql STABLE
    AS $$

-- DECLARE                                                   

-- BEGIN 

	-- input validation
	-- IF NOT EXISTS (
	-- SELECT 1 
	-- FROM carpoolvote.driver r
	-- WHERE r."UUID" = a_UUID
	-- AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
	-- 	OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
	-- 		= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
	-- )
	-- THEN
	-- 	-- return 'No Drive Offer found for those parameters';
    --     RETURN row_to_json(d_row);
	-- END IF;

    --     SELECT * INTO
    --         d_row
    --     FROM
    --         carpoolvote.vw_driver_matches
    --     WHERE
    --             uuid_driver = a_uuid
    --         AND "matchStatus" = 'MatchConfirmed';
    --         -- AND "matchStatus" = 'Canceled';

    --    RETURN row_to_json(d_row);

        SELECT row_to_json(s)
        FROM ( 
            SELECT * from
            carpoolvote.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchStatus" = 'MatchConfirmed'
        ) s ;

-- END  

$$;


ALTER FUNCTION carpoolvote.driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_exists(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
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
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
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

CREATE FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) RETURNS json
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
	AND (LOWER(r."DriverLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."DriverPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
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
-- Name: driver_pause_match(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
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

$$;


ALTER FUNCTION carpoolvote.driver_pause_match(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_proposed_matches(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) RETURNS SETOF json
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
-- Name: evaluate_match_single_pair(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE

run_now carpoolvote.match_engine_scheduler.need_run_flag%TYPE;

v_start_ts carpoolvote.match_engine_activity_log.start_ts%TYPE;
v_end_ts carpoolvote.match_engine_activity_log.end_ts%TYPE;
v_evaluated_pairs carpoolvote.match_engine_activity_log.evaluated_pairs%TYPE;
v_proposed_count carpoolvote.match_engine_activity_log.proposed_count%TYPE;
v_error_count carpoolvote.match_engine_activity_log.error_count%TYPE;
v_expired_count carpoolvote.match_engine_activity_log.expired_count%TYPE;

b_rider_all_times_expired  boolean := TRUE;
b_rider_validated boolean := TRUE;
b_driver_all_times_expired boolean := TRUE;
b_driver_validated boolean := TRUE;

RADIUS_MAX_ALLOWED integer := 100;

drive_offer_row carpoolvote.driver%ROWTYPE;
ride_request_row carpoolvote.rider%ROWTYPE;
cnt integer;
match_points integer;
time_criteria_points integer;

ride_times_rider text[];
ride_times_driver text[];
driver_time text;
rider_time text;
seconds_diff integer;

start_ride_time timestamp with time zone;
end_ride_time timestamp with time zone;
start_drive_time timestamp with time zone;
end_drive_time timestamp with time zone;

zip_origin carpoolvote.zip_codes%ROWTYPE;  -- Driver's origin
zip_pickup carpoolvote.zip_codes%ROWTYPE;  -- Rider's pickup
zip_dropoff carpoolvote.zip_codes%ROWTYPE; -- Rider's dropoff

distance_origin_pickup double precision;  -- From driver origin to rider pickup point
distance_origin_dropoff double precision; -- From driver origin to rider drop off point

g_uuid_driver character varying(50);
g_uuid_rider  character varying(50);
g_record record;
g_email_body text;
g_sms_body text;

BEGIN

	run_now := true;
	--BEGIN
	--	INSERT INTO carpoolvote.match_engine_scheduler VALUES(true);
	--EXCEPTION WHEN OTHERS
	--THEN
		-- ignore
	--END;
	--SELECT need_run_flag INTO run_now from carpoolvote.match_engine_scheduler LIMIT 1;
	IF run_now
	THEN

		
	
		-- Initialize Counters
		v_start_ts := now();
		v_evaluated_pairs := 0;
		v_proposed_count := 0;
		v_error_count := 0;
		v_expired_count := 0;

		
		
		FOR ride_request_row in SELECT * from carpoolvote.rider r
			WHERE r.status in ('Pending','MatchProposed') AND r."UUID" like arg_uuid_rider || '%'
		LOOP
		
			IF length(ride_request_row."AvailableRideTimesLocal") = 0
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Invalid AvailableRideTimes'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;
			

			BEGIN
				-- DriverCollectionZIP
				-- DriverCollectionRadius
			
				SELECT * INTO zip_pickup FROM carpoolvote.zip_codes WHERE zip=ride_request_row."RiderCollectionZIP";
				SELECT * INTO zip_dropoff FROM carpoolvote.zip_codes WHERE zip=ride_request_row."RiderDropOffZIP";
			
			EXCEPTION WHEN OTHERS
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Unknown/Invalid RiderCollectionZIP or RiderDropOffZIP'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END;
			
			IF ride_request_row."TotalPartySize" = 0
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Invalid TotalPartySize'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;
	
	
			-- split AvailableRideTimesLocal in individual time intervals
			ride_times_rider := string_to_array(ride_request_row."AvailableRideTimesLocal", '|');
			b_rider_all_times_expired := TRUE;  -- Assumes all expired
			FOREACH rider_time IN ARRAY ride_times_rider
			LOOP
				BEGIN
					-- each time interval is in ISO8601 format
					-- 2016-10-23T10:00:00-0500/2016-10-23T11:00:00-0500
					start_ride_time := substr(rider_time, 1, 24)::timestamp with time zone;
					end_ride_time := substr(rider_time, 26, 24)::timestamp with time zone;
					
					IF start_ride_time > end_ride_time
					THEN
						UPDATE carpoolvote.rider 
						SET status='Failed', status_info='Invalid value in AvailableRideTimes:' || rider_time
						WHERE "UUID"=ride_request_row."UUID";
				
						b_rider_validated := FALSE;
					ELSE
					
						IF end_ride_time > now()   ----   --[NOW]--[S]--[E]   : not expired
						THEN                       ----   --[S]---[NOW]--[E]  : not expired
													      --[S]--[E]----[NOW] : expired
							b_rider_all_times_expired := FALSE;
						END IF;
					END IF;
				EXCEPTION WHEN OTHERS
				THEN				
					UPDATE carpoolvote.rider
					SET status='Failed', status_info='Invalid value in AvailableRideTimes:' || rider_time
					WHERE "UUID"=ride_request_row."UUID";

					b_rider_validated := FALSE;
				END;
				
				IF b_rider_all_times_expired
				THEN
					UPDATE carpoolvote.rider r
					SET status='Expired', status_info='All AvailableRideTimes are expired'
					WHERE "UUID"=ride_request_row."UUID";

					v_expired_count := v_expired_count +1;
					
					b_rider_validated := FALSE;
				END IF;
				
			END LOOP;
	
			IF b_rider_validated
			THEN
			
 				FOR drive_offer_row in SELECT * from carpoolvote.driver d
 					WHERE status IN ('Pending','MatchProposed','MatchConfirmed')
 					AND ((ride_request_row."NeedWheelchair"=true AND d."DriverCanLoadRiderWithWheelchair" = true) -- driver must be able to transport wheelchair if rider needs it
 						OR ride_request_row."NeedWheelchair"=false)   -- but a driver equipped for wheelchair may drive someone who does not need one
 					AND ride_request_row."TotalPartySize" <= d."SeatCount"  -- driver must be able to accommodate the entire party in one ride

 				LOOP
 
 					IF length(drive_offer_row."AvailableDriveTimesLocal") = 0
 					THEN
 						UPDATE carpoolvote.driver 
 						SET status='Failed', status_info='Invalid AvailableDriveTimes'
 						WHERE "UUID"=drive_offer_row."UUID";
 				
 						b_driver_validated := false;
 					END IF;
 
 					BEGIN
 						SELECT * INTO zip_origin FROM carpoolvote.zip_codes WHERE zip=drive_offer_row."DriverCollectionZIP";
 					EXCEPTION WHEN OTHERS
 					THEN
 						UPDATE carpoolvote.driver 
 						SET status='Failed', status_info='Invalid DriverCollectionZIP'
 						WHERE "UUID"=drive_offer_row."UUID";
 					
 						b_driver_validated := FALSE;
 					END;
 					
 					
 					-- split AvailableDriveTimesLocal in individual time intervals
 					-- NOTE : we do not want actual JSON here...
 					-- FORMAT should be like this 
 					-- 2016-10-01T08:00:00-0500/2016-10-01T10:00:00-0500|2016-10-01T10:00:00-0500/2016-10-01T22:00:00-0500|2016-10-01T22:00:00-0500/2016-10-01T23:00:00-0500
 					ride_times_driver := string_to_array(drive_offer_row."AvailableDriveTimesLocal", '|');
					b_driver_all_times_expired := TRUE;
 					FOREACH driver_time IN ARRAY ride_times_driver
					LOOP
						BEGIN
							-- each time interval is in ISO8601 format
							-- 2016-10-23T10:00:00-0500/2016-10-23T11:00:00-0500
							start_drive_time := substr(driver_time, 1, 24)::timestamp with time zone;
							end_drive_time := substr(driver_time, 26, 24)::timestamp with time zone;
							
							IF start_drive_time > end_drive_time
							THEN
								UPDATE carpoolvote.driver 
								SET status='Failed', status_info='Invalid value in AvailableDriveTimes:' || driver_time
								WHERE "UUID"=drive_offer_row."UUID";
				
								b_driver_validated := FALSE;
							ELSE
							
								IF end_drive_time > now()   ----   --[NOW]--[S]--[E]   : not expired
								THEN                       ----   --[S]---[NOW]--[E]  : not expired
													      --[S]--[E]----[NOW] : expired
									b_driver_all_times_expired := FALSE;
								END IF;
							END IF;
							
						EXCEPTION WHEN OTHERS
						THEN
							UPDATE carpoolvote.driver 
							SET status='Failed', status_info='Invalid value in AvailableDriveTimes :' || driver_time
							WHERE "UUID"=drive_offer_row."UUID";

							b_driver_validated := FALSE;
						END;
		
		
						IF b_driver_all_times_expired
						THEN
							UPDATE carpoolvote.driver
							SET status='Expired', status_info='All AvailableDriveTimes are expired'
							WHERE "UUID"=drive_offer_row."UUID";

							v_expired_count := v_expired_count +1;
					
							b_driver_validated := FALSE;
						END IF;
				
					END LOOP;		
					IF 	b_driver_validated
					THEN
				
						match_points := 0;
				
						-- Compare RiderCollectionZIP with DriverCollectionZIP / DriverCollectionRadius
						distance_origin_pickup := carpoolvote.distance(
									zip_origin.latitude_numeric,
									zip_origin.longitude_numeric,
									zip_pickup.latitude_numeric,
									zip_pickup.longitude_numeric);
						
						distance_origin_dropoff := carpoolvote.distance(
									zip_origin.latitude_numeric,
									zip_origin.longitude_numeric,
									zip_dropoff.latitude_numeric,
									zip_dropoff.longitude_numeric);

						RAISE NOTICE 'distance_origin_pickup=%', distance_origin_pickup;
						RAISE NOTICE 'distance_origin_dropoff=%', distance_origin_pickup;
						
						IF distance_origin_pickup < RADIUS_MAX_ALLOWED AND distance_origin_dropoff < RADIUS_MAX_ALLOWED
						THEN

							-- driver/rider distance ranking
							IF distance_origin_pickup <= drive_offer_row."DriverCollectionRadius" 
								AND distance_origin_dropoff <= drive_offer_row."DriverCollectionRadius"
							THEN
								match_points := match_points + 200 
									- distance_origin_pickup -- closest distance gets more points 
									- distance_origin_dropoff ;
							END IF; 
							
							RAISE NOTICE 'D-%, R-%, distance ranking Score=%', 
										drive_offer_row."UUID", 
										ride_request_row."UUID", 
										match_points;
			
							
							-- vulnerable rider matching
							IF ride_request_row."RiderIsVulnerable" = false
							THEN
								match_points := match_points + 200;
							ELSIF ride_request_row."RiderIsVulnerable" = true 
								AND drive_offer_row."DrivingOnBehalfOfOrganization" 
							THEN
								match_points := match_points + 200;
							END IF;
					
							RAISE NOTICE 'D-%, R-%, vulnerable ranking Score=%', 
										drive_offer_row."UUID", 
										ride_request_row."UUID", 
										match_points;
			
							-- time matching
							-- Each combination of rider time and driver time can give a potential match
							FOREACH driver_time IN ARRAY ride_times_driver
							LOOP
								FOREACH rider_time IN ARRAY ride_times_rider
								LOOP
									
									v_evaluated_pairs := v_evaluated_pairs +1;
									
									-- each time interval is in ISO8601 format
									-- 2016-10-23T10:00:00-0500/2016-10-23T11:00:00-0500
									start_ride_time := substr(rider_time, 1, 24)::timestamp with time zone;
									end_ride_time := substr(rider_time, 26, 24)::timestamp with time zone;
									
									-- each time interval is in ISO8601 format
									-- 2016-10-23T10:00:00-0500/2016-10-23T11:00:00-0500
									start_drive_time := substr(driver_time, 1, 24)::timestamp with time zone;
									end_drive_time := substr(driver_time, 26, 24)::timestamp with time zone;
									
									
									time_criteria_points := 200;
									
									IF end_drive_time < start_ride_time       -- [ddddd]  [rrrrrr]
										OR end_ride_time < start_drive_time   -- [rrrrr]  [dddddd]
									THEN
										-- we're totally disconnected
										
										IF end_drive_time < start_ride_time
										THEN
										
											-- substracts one point per minute the driver is outside the rider interval
											time_criteria_points := 
												time_criteria_points - abs(EXTRACT(EPOCH FROM (start_ride_time - end_drive_time))) / 60;
										ELSIF end_ride_time < start_drive_time
										THEN
											time_criteria_points := 
												time_criteria_points - abs(EXTRACT(EPOCH FROM (start_drive_time - end_ride_time))) / 60;
										END IF;
										
										if time_criteria_points < 0
										THEN
											time_criteria_points := 0; 
										END IF;
										
									-- ELSIF start_drive_time < start_ride_time  -- [ddd[rdrdrdrdrd]ddd] 
										-- AND end_drive_time > end_ride_time
									-- THEN
										-- -- perfect! we're in the interval
									-- ELSIF start_drive_time < start_ride_time  -- [ddddddd[rdrdrd]rrrr]
										-- AND start_ride_time < end_drive_time
									-- THEN
										-- -- We're at least partially in the interval
									-- ELSIF  start_ride_time < start_drive_time -- [rrrrr[rdrdrd]ddddd]
										-- AND start_drive_time < end_ride_time
									-- THEN
										-- -- We're at least partially in the interval
									-- ELSIF start_ride_time < start_drive_time  -- [rrr[rdrdrdrdrd]rrrrr]
										-- AND end_drive_time < end_ride_time
									-- THEN
										-- -- We're completely in the interval
									END IF;
									
									RAISE NOTICE 'D-%, R-%, final ranking Score=%', 
									drive_offer_row."UUID", 
									ride_request_row."UUID", 
									match_points+time_criteria_points;
									
									IF match_points + time_criteria_points >= 300
									THEN
									
										BEGIN

											
											-- The status of the ride request is 
											
											UPDATE carpoolvote.rider r
											SET status='MatchProposed'
											WHERE r."UUID" = ride_request_row."UUID";

											-- If already MatchConfirmed, keep it as is
											IF drive_offer_row.status = 'Pending'
											THEN
												UPDATE carpoolvote.driver d
												SET status='MatchProposed'
												WHERE d."UUID" = drive_offer_row."UUID";
											END IF;
											
											v_proposed_count := v_proposed_count +1;
											
											RAISE NOTICE 'Proposed Match, Rider=%, Driver=%, Score=%',
														 ride_request_row."UUID", drive_offer_row."UUID", match_points + time_criteria_points;
										EXCEPTION WHEN unique_violation
										THEN
											-- ignore
											-- don't insert duplicate match
										END;                 
									 
									END IF;
									
								END LOOP;
							
								
							END LOOP;

						END IF; -- distances are within radius tolerance
					ELSE
						v_error_count := v_error_count +1;
					END IF; -- driver is validated
 				END LOOP; -- for each drive offer
			ELSE
				v_error_count := v_error_count +1;
			END IF; -- rider is validated
			
		END LOOP; -- for each ride request
		

		
		--v_end_ts := now();
		-- Update activity log
		--INSERT INTO carpoolvote.match_engine_activity_log (
				--start_ts, end_ts , evaluated_pairs,
				--proposed_count, error_count, expired_count)
		--VALUES(v_start_ts, v_end_ts, v_evaluated_pairs,
				--v_proposed_count, v_error_count, v_expired_count);
		
		-- Update scheduler
		-- UPDATE carpoolvote.match_engine_scheduler set need_run_flag = false;
		
		
		
	END IF;
	
	return '';
END
$$;


ALTER FUNCTION carpoolvote.evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) OWNER TO carpool_admins;

--
-- Name: fct_modified_column(); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION fct_modified_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_updated_ts = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION carpoolvote.fct_modified_column() OWNER TO carpool_admins;

--
-- Name: get_param_value(character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION get_param_value(a_param_name character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE

v_env carpoolvote.params.value%TYPE;

BEGIN

v_env := NULL;

BEGIN
	SELECT value INTO v_env FROM carpoolvote.params WHERE name=a_param_name;
EXCEPTION WHEN OTHERS
THEN
	v_env := NULL;
END;

RETURN v_env;

END
$$;


ALTER FUNCTION carpoolvote.get_param_value(a_param_name character varying) OWNER TO carpool_admins;

--
-- Name: perform_match(); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION perform_match() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE

run_now carpoolvote.match_engine_scheduler.need_run_flag%TYPE;

v_start_ts carpoolvote.match_engine_activity_log.start_ts%TYPE;
v_end_ts carpoolvote.match_engine_activity_log.end_ts%TYPE;
v_evaluated_pairs carpoolvote.match_engine_activity_log.evaluated_pairs%TYPE;
v_proposed_count carpoolvote.match_engine_activity_log.proposed_count%TYPE;
v_error_count carpoolvote.match_engine_activity_log.error_count%TYPE;
v_expired_count carpoolvote.match_engine_activity_log.expired_count%TYPE;

b_rider_all_times_expired  boolean := TRUE;
b_rider_validated boolean := TRUE;
b_driver_all_times_expired boolean := TRUE;
b_driver_validated boolean := TRUE;

RADIUS_MAX_ALLOWED integer := 100;
BEYOND_RADIUS_TOLERANCE integer := 20;

drive_offer_row carpoolvote.driver%ROWTYPE;
ride_request_row carpoolvote.rider%ROWTYPE;
cnt integer;
match_points integer;
match_points_with_time integer;
time_criteria_points integer;
v_existing_score integer;

ride_times_rider text[];
ride_times_driver text[];
driver_time text;
rider_time text;
seconds_diff integer;

start_ride_time timestamp without time zone;
end_ride_time timestamp without time zone;
start_drive_time timestamp without time zone;
end_drive_time timestamp without time zone;

zip_origin carpoolvote.zip_codes%ROWTYPE;  -- Driver's origin
zip_pickup carpoolvote.zip_codes%ROWTYPE;  -- Rider's pickup
zip_dropoff carpoolvote.zip_codes%ROWTYPE; -- Rider's dropoff

distance_origin_pickup double precision;  -- From driver origin to rider pickup point
distance_origin_dropoff double precision; -- From driver origin to rider drop off point

g_uuid_driver character varying(50);
g_uuid_rider  character varying(50);
g_record record;
g_email_body text;
g_sms_body text;

v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
v_html_header carpoolvote.outgoing_email.body%TYPE;
v_html_body   carpoolvote.outgoing_email.body%TYPE;
v_html_footer carpoolvote.outgoing_email.body%TYPE;

v_loop_cnt integer;
v_row_style text;

BEGIN

	run_now := true;
	--BEGIN
	--	INSERT INTO carpoolvote.match_engine_scheduler VALUES(true);
	--EXCEPTION WHEN OTHERS
	--THEN
		-- ignore
	--END;
	--SELECT need_run_flag INTO run_now from carpoolvote.match_engine_scheduler LIMIT 1;
	IF run_now
	THEN

		CREATE TEMPORARY TABLE match_notifications_buffer (
		 uuid_driver character varying(50) NOT NULL,
		 uuid_rider character varying(50) NOT NULL,
		 score smallint
		);
	
		-- Initialize Counters
		v_start_ts := now();
		v_evaluated_pairs := 0;
		v_proposed_count := 0;
		v_error_count := 0;
		v_expired_count := 0;

		
		
		FOR ride_request_row in SELECT * from carpoolvote.rider r
			WHERE r.status in ('Pending','MatchProposed')
		LOOP
		
			IF length(ride_request_row."AvailableRideTimesLocal") = 0
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Invalid AvailableRideTimes'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;
			

			BEGIN
				-- DriverCollectionZIP
				-- DriverCollectionRadius
			
				SELECT * INTO zip_pickup FROM carpoolvote.zip_codes WHERE zip=ride_request_row."RiderCollectionZIP";
				SELECT * INTO zip_dropoff FROM carpoolvote.zip_codes WHERE zip=ride_request_row."RiderDropOffZIP";
			
			EXCEPTION WHEN OTHERS
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Unknown/Invalid RiderCollectionZIP or RiderDropOffZIP'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END;
			
			IF ride_request_row."TotalPartySize" = 0
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Invalid TotalPartySize'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;

            -- zip code verification
			IF NOT EXISTS
				(SELECT 1 FROM carpoolvote.zip_codes z where z.zip = ride_request_row."RiderCollectionZIP" AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Invalid/Not Found RiderCollectionZIP:' || ride_request_row."RiderCollectionZIP"
				WHERE "UUID"=ride_request_row."UUID";
				b_rider_validated := FALSE;
			END IF;

			IF NOT EXISTS 
				(SELECT 1 FROM carpoolvote.zip_codes z WHERE z.zip = ride_request_row."RiderDropOffZIP" AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
			THEN
				UPDATE carpoolvote.rider 
				SET status='Failed', status_info='Invalid/Not Found RiderDropOffZIP:' || ride_request_row."RiderDropOffZIP"
				WHERE "UUID"=ride_request_row."UUID";
				b_rider_validated := FALSE;
			END IF;	
	
			-- split AvailableRideTimesLocal in individual time intervals
			ride_times_rider := string_to_array(ride_request_row."AvailableRideTimesLocal", '|');
			b_rider_all_times_expired := TRUE;  -- Assumes all expired
			FOREACH rider_time IN ARRAY ride_times_rider
			LOOP
				BEGIN
					-- each time interval is in ISO8601 format					
					-- new format without timezone : 2016-10-01T02:00/2016-10-01T03:00
					start_ride_time :=  (substring(rider_time from 1 for (position ('/' in rider_time)-1)))::timestamp without time zone;
					end_ride_time :=    (substring(rider_time from position ('/' in rider_time)))::timestamp without time zone;
					
					IF start_ride_time > end_ride_time
					THEN
						UPDATE carpoolvote.rider 
						SET status='Failed', status_info='Invalid value in AvailableRideTimes:' || rider_time
						WHERE "UUID"=ride_request_row."UUID";
				
						b_rider_validated := FALSE;
					ELSE
					
						IF end_ride_time > now()   ----   --[NOW]--[S]--[E]   : not expired
						THEN                       ----   --[S]---[NOW]--[E]  : not expired
													      --[S]--[E]----[NOW] : expired
							b_rider_all_times_expired := FALSE;
						END IF;
					END IF;
				EXCEPTION WHEN OTHERS
				THEN				
					UPDATE carpoolvote.rider
					SET status='Failed', status_info='Invalid value in AvailableRideTimes:' || rider_time
					WHERE "UUID"=ride_request_row."UUID";

					b_rider_validated := FALSE;
				END;
				
				IF b_rider_all_times_expired
				THEN
					UPDATE carpoolvote.rider r
					SET status='Expired', status_info='All AvailableRideTimes are expired'
					WHERE "UUID"=ride_request_row."UUID";

					v_expired_count := v_expired_count +1;
					
					b_rider_validated := FALSE;
				END IF;
								
			END LOOP;
	
			IF b_rider_validated
			THEN
			
 				FOR drive_offer_row in SELECT * from carpoolvote.driver d
 					WHERE status IN ('Pending','MatchProposed','MatchConfirmed')
					AND d."ReadyToMatch" = true
 					AND ((ride_request_row."NeedWheelchair"=true AND d."DriverCanLoadRiderWithWheelchair" = true) -- driver must be able to transport wheelchair if rider needs it
 						OR ride_request_row."NeedWheelchair"=false)   -- but a driver equipped for wheelchair may drive someone who does not need one
 					AND ride_request_row."TotalPartySize" <= d."SeatCount"  -- driver must be able to accommodate the entire party in one ride
                    
 				LOOP
                    IF EXISTS (SELECT 1 FROM carpoolvote.match
                                    WHERE uuid_driver = drive_offer_row."UUID" and uuid_rider = ride_request_row."UUID")
                    THEN
                        CONTINUE;  -- skip evaluating this pair since there is already a match
                    END IF;
                    
 					IF length(drive_offer_row."AvailableDriveTimesLocal") = 0
 					THEN
 						UPDATE carpoolvote.driver 
 						SET status='Failed', status_info='Invalid AvailableDriveTimes'
 						WHERE "UUID"=drive_offer_row."UUID";
 				
 						b_driver_validated := false;
 					END IF;
 
					IF NOT EXISTS 
						(SELECT 1 FROM carpoolvote.zip_codes z where z.zip = drive_offer_row."DriverCollectionZIP" AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
					THEN
						UPDATE carpoolvote.driver 
						SET status='Failed', status_info='Invalid/Not Found DriverCollectionZIP:' || drive_offer_row."DriverCollectionZIP"
						WHERE "UUID"=drive_offer_row."UUID";
						b_driver_validated := FALSE;
					END IF; 	
 
 					BEGIN
 						SELECT * INTO zip_origin FROM carpoolvote.zip_codes WHERE zip=drive_offer_row."DriverCollectionZIP";
 					EXCEPTION WHEN OTHERS
 					THEN
 						UPDATE carpoolvote.driver 
 						SET status='Failed', status_info='Invalid DriverCollectionZIP'
 						WHERE "UUID"=drive_offer_row."UUID";
 					
 						b_driver_validated := FALSE;
 					END;
 					
 					-- split AvailableDriveTimesLocal in individual time intervals
 					-- FORMAT should be like this 
 					-- 2016-10-01T02:00/2016-10-01T03:00|2016-10-01T02:00/2016-10-01T03:00|2016-10-01T02:00/2016-10-01T03:00
 					ride_times_driver := string_to_array(drive_offer_row."AvailableDriveTimesLocal", '|');
					b_driver_all_times_expired := TRUE;
 					FOREACH driver_time IN ARRAY ride_times_driver
					LOOP
						BEGIN
							-- each time interval is in ISO8601 format
							-- new format without timezone : 2016-10-01T02:00/2016-10-01T03:00
							start_drive_time :=  (substring(driver_time from 1 for (position ('/' in driver_time)-1)))::timestamp without time zone;
							end_drive_time :=    (substring(driver_time from position ('/' in driver_time)))::timestamp without time zone;
					
							IF start_drive_time > end_drive_time
							THEN
								UPDATE carpoolvote.driver 
								SET status='Failed', status_info='Invalid value in AvailableDriveTimes:' || driver_time
								WHERE "UUID"=drive_offer_row."UUID";
				
								b_driver_validated := FALSE;
							ELSE
							
								IF end_drive_time > now()   ----   --[NOW]--[S]--[E]   : not expired
								THEN                       ----   --[S]---[NOW]--[E]  : not expired
													      --[S]--[E]----[NOW] : expired
									b_driver_all_times_expired := FALSE;
								END IF;
							END IF;
							
						EXCEPTION WHEN OTHERS
						THEN
							UPDATE carpoolvote.driver 
							SET status='Failed', status_info='Invalid value in AvailableDriveTimes :' || driver_time
							WHERE "UUID"=drive_offer_row."UUID";

							b_driver_validated := FALSE;
						END;
		
		
						IF b_driver_all_times_expired
						THEN
							UPDATE carpoolvote.driver
							SET status='Expired', status_info='All AvailableDriveTimes are expired'
							WHERE "UUID"=drive_offer_row."UUID";

							v_expired_count := v_expired_count +1;
					
							b_driver_validated := FALSE;
						END IF;
				
					END LOOP;		
					IF 	b_driver_validated
					THEN
				
						match_points := 0;
				
						-- Compare RiderCollectionZIP with DriverCollectionZIP / DriverCollectionRadius
						distance_origin_pickup := carpoolvote.distance(
									zip_origin.latitude_numeric,
									zip_origin.longitude_numeric,
									zip_pickup.latitude_numeric,
									zip_pickup.longitude_numeric);
						
						distance_origin_dropoff := carpoolvote.distance(
									zip_origin.latitude_numeric,
									zip_origin.longitude_numeric,
									zip_dropoff.latitude_numeric,
									zip_dropoff.longitude_numeric);

									
						--RAISE NOTICE 'distance_origin_pickup=%', distance_origin_pickup;
						--RAISE NOTICE 'distance_origin_dropoff=%', distance_origin_pickup;
						
						IF distance_origin_pickup < RADIUS_MAX_ALLOWED AND distance_origin_dropoff < RADIUS_MAX_ALLOWED
							AND distance_origin_pickup < (drive_offer_row."DriverCollectionRadius" + BEYOND_RADIUS_TOLERANCE)
							AND distance_origin_dropoff < (drive_offer_row."DriverCollectionRadius" + BEYOND_RADIUS_TOLERANCE)
						THEN

							-- driver/rider distance ranking
							IF distance_origin_pickup <= drive_offer_row."DriverCollectionRadius" 
								AND distance_origin_dropoff <= drive_offer_row."DriverCollectionRadius"
							THEN
								match_points := match_points + 200 
									- distance_origin_pickup  -- closest distance gets more points 
									- distance_origin_dropoff ;
							END IF; 
							
							--RAISE NOTICE 'D-%, R-%, distance ranking Score=%', 
										--drive_offer_row."UUID", 
										--ride_request_row."UUID", 
										--match_points;
			
							
							-- vulnerable rider matching
							IF ride_request_row."RiderIsVulnerable" = false
							THEN
								match_points := match_points + 200;
							ELSIF ride_request_row."RiderIsVulnerable" = true 
								AND drive_offer_row."DrivingOnBehalfOfOrganization" 
							THEN
								match_points := match_points + 200;
							END IF;
					
							--RAISE NOTICE 'D-%, R-%, vulnerable ranking Score=%', 
										--drive_offer_row."UUID", 
										--ride_request_row."UUID", 
										--match_points;
			
							-- time matching
							-- Each combination of rider time and driver time can give a potential match
							FOREACH driver_time IN ARRAY ride_times_driver
							LOOP
								FOREACH rider_time IN ARRAY ride_times_rider
								LOOP
									
									v_evaluated_pairs := v_evaluated_pairs +1;
									
									-- each time interval is in ISO8601 format
									-- new format without timezone : 2016-10-01T02:00/2016-10-01T03:00
									start_ride_time :=  (substring(rider_time from 1 for (position ('/' in rider_time)-1)))::timestamp without time zone;
									end_ride_time :=    (substring(rider_time from position ('/' in rider_time)))::timestamp without time zone;
					
									-- each time interval is in ISO8601 format
									-- 2016-10-23T10:00:00-0500/2016-10-23T11:00:00-0500
									start_drive_time :=  (substring(driver_time from 1 for (position ('/' in driver_time)-1)))::timestamp without time zone;
									end_drive_time :=    (substring(driver_time from position ('/' in driver_time)))::timestamp without time zone;

									
									
									time_criteria_points := 200;
									
									IF end_drive_time < start_ride_time       -- [ddddd]  [rrrrrr]
										OR end_ride_time < start_drive_time   -- [rrrrr]  [dddddd]
									THEN
										-- we're totally disconnected
										
										IF end_drive_time < start_ride_time
										THEN
										
											-- substracts one point per minute the driver is outside the rider interval
											time_criteria_points := 
												time_criteria_points - abs(EXTRACT(EPOCH FROM (start_ride_time - end_drive_time))) / 60;
										ELSIF end_ride_time < start_drive_time
										THEN
											time_criteria_points := 
												time_criteria_points - abs(EXTRACT(EPOCH FROM (start_drive_time - end_ride_time))) / 60;
										END IF;
										
										if time_criteria_points < 0
										THEN
											time_criteria_points := 0; 
										END IF;
										
									-- ELSIF start_drive_time < start_ride_time  -- [ddd[rdrdrdrdrd]ddd] 
										-- AND end_drive_time > end_ride_time
									-- THEN
										-- -- perfect! we're in the interval
									-- ELSIF start_drive_time < start_ride_time  -- [ddddddd[rdrdrd]rrrr]
										-- AND start_ride_time < end_drive_time
									-- THEN
										-- -- We're at least partially in the interval
									-- ELSIF  start_ride_time < start_drive_time -- [rrrrr[rdrdrd]ddddd]
										-- AND start_drive_time < end_ride_time
									-- THEN
										-- -- We're at least partially in the interval
									-- ELSIF start_ride_time < start_drive_time  -- [rrr[rdrdrdrdrd]rrrrr]
										-- AND end_drive_time < end_ride_time
									-- THEN
										-- -- We're completely in the interval
									END IF;
									
                                    match_points_with_time := match_points + time_criteria_points;
                                    
									--RAISE NOTICE 'D-%, R-%, time ranking ranking Score=%', 
										--drive_offer_row."UUID", 
										--ride_request_row."UUID", 
										--match_points_with_time;
									
									IF match_points_with_time >= 300
									THEN
                                        IF EXISTS (
                                            SELECT 1 FROM match_notifications_buffer
                                                WHERE uuid_rider = ride_request_row."UUID"
                                                AND uuid_driver = drive_offer_row."UUID")
                                        THEN
                                        
                                            UPDATE match_notifications_buffer
                                            SET score = match_points_with_time
                                            WHERE uuid_rider = ride_request_row."UUID"
                                            AND uuid_driver = drive_offer_row."UUID"
                                            AND score < match_points_with_time;
                                            
                                            -- new match only if score if higher 
                                            IF FOUND THEN
                                                UPDATE carpoolvote.match
                                                SET score = match_points_with_time
                                                WHERE uuid_rider = ride_request_row."UUID"
                                                AND uuid_driver = drive_offer_row."UUID"
                                                AND score < match_points_with_time;
                                                
                                                RAISE NOTICE 'Better Proposed Match, Rider=%, Driver=%, Score=%',
														ride_request_row."UUID", drive_offer_row."UUID", match_points_with_time;
                                                
                                            END IF;
                                        
                                        ELSE
											INSERT INTO carpoolvote.match (uuid_rider, uuid_driver, score, status)
												VALUES (
													ride_request_row."UUID",               --pkey
													drive_offer_row."UUID",                --pkey 
													match_points_with_time,                --pkey
													'MatchProposed'
												);

											INSERT INTO match_notifications_buffer (uuid_driver, uuid_rider, score)
                                                VALUES (drive_offer_row."UUID", ride_request_row."UUID", match_points_with_time);
																						
											UPDATE carpoolvote.rider r
											SET status='MatchProposed'
											WHERE r."UUID" = ride_request_row."UUID";

											-- If already MatchConfirmed, keep it as is
											UPDATE carpoolvote.driver d
												SET status='MatchProposed'
												WHERE d."UUID" = drive_offer_row."UUID"
                                                AND status='Pending';
											
											v_proposed_count := v_proposed_count +1;
                                            
                                            RAISE NOTICE 'Proposed Match, Rider=%, Driver=%, Score=%',
                                                ride_request_row."UUID", drive_offer_row."UUID", match_points_with_time;
                                        END IF;
										                 
									 
									END IF;
									
								END LOOP;
							
								
							END LOOP;

						END IF; -- distances are within radius tolerance
					ELSE
						v_error_count := v_error_count +1;
					END IF; -- driver is validated
 				END LOOP; -- for each drive offer
			ELSE
				v_error_count := v_error_count +1;
			END IF; -- rider is validated
			
		END LOOP; -- for each ride request

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

		
		-- send notifications to driver only. Riders will be waiting to be contacted
		FOR drive_offer_row IN SELECT * FROM carpoolvote.driver d
								WHERE d."UUID" IN (SELECT DISTINCT uuid_driver FROM match_notifications_buffer)
		LOOP
		
            v_html_body := '<body>'
            || '<p>Dear ' || drive_offer_row."DriverFirstName" ||  ' ' || drive_offer_row."DriverLastName" || ', <p>' 
            || '<p>Great news - we found riders who match your criteria!</p>'
            || '<p><table>'
            || '<tr>' 
            || '<td class="oddRow">Action</td>' 
            || '<td class="oddRow">Score (best=600)</td>' 
            || '<td class="oddRow">Pick-up location</td>'
            || '<td class="oddRow">Destination</td>'
            || '<td class="oddRow">Preferred Ride Times</td>'
            || '<td class="oddRow">Party Size</td>'
            || '<td class="oddRow">Wheelchair accessibility needed</td>'
            || '<td class="oddRow">Two-way trip needed</td>'
            || '<td class="oddRow">Notes</td>'
            || '<td class="oddRow">Name</td>'
            || '<td class="oddRow">Email (*=preferred)</td>'
            || '<td class="oddRow">Phone Number (*)=preferred</td>'
            || '</tr>';

			--RAISE NOTICE 'BODY 1 : %', v_html_body;
			
            v_loop_cnt := 0;
			FOR g_record IN SELECT * FROM carpoolvote.match m 
									WHERE m.uuid_driver = drive_offer_row."UUID" order by score desc
			LOOP
                v_row_style := CASE WHEN v_loop_cnt % 2 =1 THEN 'oddRow' else 'evenRow' END;
					
				SELECT * INTO ride_request_row FROM carpoolvote.rider r
												WHERE r."UUID" = g_record.uuid_rider;

				v_html_body := v_html_body 
                    || '<tr>' 
                    || '<td class="' || v_row_style || '">' ||
                        CASE WHEN g_record.status='MatchProposed' THEN '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/accept-driver-match' 
                            || '?UUID_driver=' || drive_offer_row."UUID"
                            || '&UUID_rider=' || g_record.uuid_rider
                            || '&Score=' || g_record.score
                            || '&DriverPhone=' || carpoolvote.urlencode(drive_offer_row."DriverLastName" )   -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
                            || '">Accept</a>'
                        ELSE g_record.status END || '</td>'
                    || '<td class="' || v_row_style || '">' || g_record.score || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE(ride_request_row."RiderCollectionAddress" || ', ', '') || ride_request_row."RiderCollectionZIP" || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE(ride_request_row."RiderDestinationAddress" || ', ', '') || ride_request_row."RiderDropOffZIP" || '</td>'
                    || '<td class="' || v_row_style || '">' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-')  || '</td>'
                    || '<td class="' || v_row_style || '">' || ride_request_row."TotalPartySize" || '</td>'
                    || '<td class="' || v_row_style || '">' || CASE WHEN ride_request_row."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td>'
                    || '<td class="' || v_row_style || '">' || CASE WHEN ride_request_row."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE (ride_request_row."RiderAccommodationNotes", ' ') || '</td>'
                    || '<td class="' || v_row_style || '">' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName"  || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE(ride_request_row."RiderEmail", ' ') || CASE WHEN coalesce(ride_request_row."RiderPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE(ride_request_row."RiderPhone", ' ') || CASE WHEN coalesce(ride_request_row."RiderPreferredContact" LIKE '%Phone%', false) THEN '(*)' Else ' ' END || '</td>'
                    || '</tr>';
                
				--RAISE NOTICE 'BODY 2 : % % %', v_html_body, v_row_style, ride_request_row."UUID";
				
				
				v_loop_cnt := v_loop_cnt + 1;
			END LOOP;
			
			
			--RAISE NOTICE 'BODY 3 : %', v_html_body;
			
            v_html_body := v_html_body || '</table></p>'
                || '<p>If you do not wish to accept the proposed rides, you do not need to do anything. A match is only confirmed once you have accepted it.</p>'
				|| '<p>If you do not with to receive future notifications about new proposed matches for this Driver Offer, please <a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/pause-match-driver?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || carpoolvote.urlencode(drive_offer_row."DriverLastName") ||  '">click here</a></p>'            
                || '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || carpoolvote.urlencode(drive_offer_row."DriverLastName") ||  '">Cancel your Drive Offer</a></p>'
                || '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=driver&uuid=' || drive_offer_row."UUID" || '">self-service portal</a>.</p>'
				|| '<p>Warm wishes</p>'
                || '<p>The CarpoolVote.com team.</p>'
                || '</body>';

            v_body := v_html_header || v_html_body || v_html_footer;
			--RAISE NOTICE 	'%', drive_offer_row."UUID";
			--RAISE NOTICE '%', v_body;
			--RAISE NOTICE '%', v_html_header;
			--RAISE NOTICE '%', v_html_body;
			--RAISE NOTICE '%', v_html_footer;
			
			IF drive_offer_row."DriverEmail" IS NOT NULL
			THEN
				INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
				VALUES (drive_offer_row."DriverEmail", 
				'Proposed rider match update!   --- [' || drive_offer_row."UUID" || ']', 
				v_body);
				
			END IF;
				
			IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
			THEN
			
				g_sms_body := 'From CarpoolVote.com\n' 
						|| 'New matches are available.\n'
				        || 'Visit the self-service page for details http://carpoolvote.com/self-service/?type=driver&uuid=' || drive_offer_row."UUID";			
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				g_sms_body);
			
			END IF;

			
		END LOOP;
		

		
		v_end_ts := now();
		-- Update activity log
		INSERT INTO carpoolvote.match_engine_activity_log (
				start_ts, end_ts , evaluated_pairs,
				proposed_count, error_count, expired_count)
		VALUES(v_start_ts, v_end_ts, v_evaluated_pairs,
				v_proposed_count, v_error_count, v_expired_count);
		
		-- Update scheduler
		-- UPDATE carpoolvote.match_engine_scheduler set need_run_flag = false;
		
		
		
	END IF;
	
	return '';
END
$$;


ALTER FUNCTION carpoolvote.perform_match() OWNER TO carpool_admins;

--
-- Name: queue_email_notif(); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION queue_email_notif() RETURNS trigger
    LANGUAGE plpgsql
    AS $$                                                                                                                  
DECLARE                                                                                                                    
 
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

    -- triggered by submitting a drive offer form                                                                          
    IF TG_TABLE_NAME = 'driver' and TG_TABLE_SCHEMA='carpoolvote'                                                  
    THEN                                                                                                                   

        IF NEW."DriverEmail" IS NOT NULL                                                                                   
        THEN                                                                                                               

            v_subject := 'Driver Offer received!   --- [' || NEW."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || NEW."DriverFirstName" ||  ' ' || NEW."DriverLastName" || ', <p>' 
			|| '<p>We have received your offer to give someone a ride to claim their vote - THANK YOU!</p>'
			|| '<p>Your Driver Offer reference is: ' || NEW."UUID" || '<br/>'
			|| 'Please keep this reference in case you need to manage your offer.</p>'
			|| 'We will get in touch as soon as there are riders who match your criteria. Please check that the below details are correct:<br/>'
			|| '<table>'
			|| '<tr><td class="evenRow">Pick-up ZIP</td><td class="evenRow">' || NEW."DriverCollectionZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Radius</td><td class="oddRow">' || NEW."DriverCollectionRadius" || ' miles</td></tr>'
			|| '<tr><td class="evenRow">Drive Times</td><td class="evenRow">' || replace(replace(replace(replace(replace(NEW."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Seats</td><td class="oddRow">' || NEW."SeatCount" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessible</td><td class="evenRow">' || CASE WHEN NEW."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || NEW."DriverPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || NEW."DriverEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || NEW."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || NEW."UUID" || '&DriverPhone=' || carpoolvote.urlencode(NEW."DriverLastName") ||  '">Cancel this offer</a></p>'  -- yes, this is correct, the API uses DriverPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;


            INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)                                             
            VALUES (NEW."DriverEmail", v_subject, v_body);                                                                 
        END IF;                                                                                                            

		IF NEW."DriverPhone" IS NOT NULL AND (position('SMS' in NEW."DriverPreferredContact") > 0)
        THEN                                                                                                               
            v_body :=  'From CarpoolVote.com ' 
					|| 'Driver offer received! Ref: ' || NEW."UUID" || ' '
					|| 'Pick-up ZIP : ' || NEW."DriverCollectionZIP" || ' '
					|| 'Radius : ' || NEW."DriverCollectionRadius" || ' '
					|| 'Drive Times  : ' || replace(replace(replace(replace(replace(NEW."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || ' '
					|| 'Seats : ' || NEW."SeatCount" || ' '
					|| 'Wheelchair accessible : ' || CASE WHEN NEW."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || ' '
					|| 'Phone Number : ' || NEW."DriverPhone" || ' '
					|| 'Self-Service portal (cancel offer, review matches etc.) : http://carpoolvote.com/self-service/?UUID_driver=' || NEW."UUID" || ' ';
--					|| 'Cancel : https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || NEW."UUID" || '&DriverPhone=' || carpoolvote.urlencode(NEW."DriverLastName");
					
            INSERT INTO carpoolvote.outgoing_sms (recipient, body)                                             
            VALUES (NEW."DriverPhone", v_body);                                                                 
        END IF;                                                                                                            
		
    -- triggered by submitting a ride request form                                                                         
    ELSIF TG_TABLE_NAME = 'rider' and TG_TABLE_SCHEMA='carpoolvote'                                                
    THEN                                                                                                                   
        IF NEW."RiderEmail" IS NOT NULL                                                                                    
        THEN                                                                                                               

			v_subject := 'Ride Request received!   --- [' || NEW."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || NEW."RiderFirstName" ||  ' ' || NEW."RiderLastName" || ', <p>' 
			|| '<p>We’ve received your request for a ride. CONGRATULATIONS on taking this step to claim your vote!</p>'
			|| '<p>Your Ride Request reference is: ' || NEW."UUID" || '<br/>'
			|| 'Please keep this reference in case you need to manage your ride request.</p>'
			|| 'We will get in touch as soon as a driver has offered to give you a ride. Please check that the below details are correct:<br/>'
			|| '<table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || replace(replace(replace(replace(replace(NEW."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || NEW."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || NEW."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || NEW."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN NEW."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN NEW."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || NEW."RiderAccommodationNotes" || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || NEW."RiderPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || NEW."RiderEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || NEW."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || NEW."UUID" || '&RiderPhone=' || carpoolvote.urlencode(NEW."RiderLastName") ||  '">Cancel this request</a></p>' -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;
            INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)                                             
            VALUES (NEW."RiderEmail", v_subject, v_body);                                                                  
        END IF;

		IF NEW."RiderPhone" IS NOT NULL AND (position('SMS' in NEW."RiderPreferredContact") > 0)                                                                               
        THEN                                                                                                               
            v_body := 'From CarpoolVote.com\n' 
					|| 'Ride Request received! Ref: ' || NEW."UUID" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(NEW."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '\n'
					|| 'Pick-up location : ' || NEW."RiderCollectionZIP" || '\n'
					|| 'Destination : ' || NEW."RiderDropOffZIP" || '\n'
					|| 'Party Size : ' || NEW."TotalPartySize" || '\n'
					|| 'Wheelchair accessibility needed : ' ||  CASE WHEN NEW."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '\n'
					|| 'Two-way trip needed : ' ||  CASE WHEN NEW."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END || '\n'
					|| 'Notes : ' ||  NEW."RiderAccommodationNotes" || '\n'
					|| 'Phone Number : ' ||  NEW."RiderPhone" || '\n'
					|| 'Self-Service portal : http://carpoolvote.com/self-service/?UUID_rider=' || NEW."UUID" || '\n'
					|| 'Cancel : https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || NEW."UUID" || '&RiderPhone=' || carpoolvote.urlencode(NEW."RiderLastName");
				
            INSERT INTO carpoolvote.outgoing_sms (recipient, body)                                             
            VALUES (NEW."RiderPhone", v_body);                                                                 
        END IF;                    
		
    END IF;                                                                                                                

    RETURN NEW;                                                                                                            
END;    
$$;


ALTER FUNCTION carpoolvote.queue_email_notif() OWNER TO carpool_admins;

--
-- Name: rider_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) RETURNS character varying
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
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
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
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by rider. No further action needed. \n'
					|| 'Rider : ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
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
		
			v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled. No further action needed. \n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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

$$;


ALTER FUNCTION carpoolvote.rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_cancel_ride_request(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
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
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
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
			
				v_body := 'From CarpoolVote.com\n'
					|| 'Confirmed Ride was canceled by rider. No further action needed. \n'
					|| 'Rider : ' || ride_request_row."RiderFirstName" || ' ' || ride_request_row."RiderLastName" || '\n'
					|| 'Pick-up location : ' || ride_request_row."RiderCollectionZIP" || '\n'
					|| 'Party Size : ' || ride_request_row."TotalPartySize" || '\n'
					|| 'Preferred Ride Times : ' || replace(replace(replace(replace(replace(ride_request_row."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-');
			
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
			
			INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)
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

$$;


ALTER FUNCTION carpoolvote.rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_confirmed_match(character varying, character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) RETURNS json
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
	AND (LOWER(r."RiderLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."RiderPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
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

CREATE FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
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
	AND (LOWER(r."RiderLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."RiderPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
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

CREATE FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) RETURNS json
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
	AND (LOWER(r."RiderLastName") = LOWER(confirmation_parameter)
		OR (regexp_replace(COALESCE(r."RiderPhone", ''), '(^(\D)*1)?\D', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace(COALESCE(confirmation_parameter, ''), '(^(\D)*1)?\D', '', 'g'))) -- strips everything that is not numeric and the first one 
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
-- Name: update_drive_offer_status(character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION update_drive_offer_status(a_uuid character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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

$$;


ALTER FUNCTION carpoolvote.update_drive_offer_status(a_uuid character varying) OWNER TO carpool_admins;

--
-- Name: update_ride_request_status(character varying); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION update_ride_request_status(a_uuid character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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

$$;


ALTER FUNCTION carpoolvote.update_ride_request_status(a_uuid character varying) OWNER TO carpool_admins;

--
-- Name: urlencode(text); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE FUNCTION urlencode(in_str text, OUT _result text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
    _i      int4;
    _temp   varchar;
    _ascii  int4;
BEGIN
    _result = '';
    FOR _i IN 1 .. length(in_str) LOOP
        _temp := substr(in_str, _i, 1);
        IF _temp ~ '[0-9a-zA-Z:/@._?#-]+' THEN
            _result := _result || _temp;
        ELSE
            _ascii := ascii(_temp);
            IF _ascii > x'07ff'::int4 THEN
                RAISE EXCEPTION 'Won''t deal with 3 (or more) byte sequences.';
            END IF;
            IF _ascii <= x'07f'::int4 THEN
                _temp := '%'||to_hex(_ascii);
            ELSE
                _temp := '%'||to_hex((_ascii & x'03f'::int4)+x'80'::int4);
                _ascii := _ascii >> 6;
                _temp := '%'||to_hex((_ascii & x'01f'::int4)+x'c0'::int4)
                            ||_temp;
            END IF;
            _result := _result || upper(_temp);
        END IF;
    END LOOP;
    RETURN ;
END;
$$;


ALTER FUNCTION carpoolvote.urlencode(in_str text, OUT _result text) OWNER TO carpool_admins;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bordering_state; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE bordering_state (
    stateabbrev1 character(2),
    stateabbrev2 character(2)
);


ALTER TABLE bordering_state OWNER TO carpool_admins;

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
    "timestamp" timestamp without time zone DEFAULT now() NOT NULL,
    helpername character varying(100) NOT NULL,
    helperemail character varying(250) NOT NULL,
    helpercapability character varying(500)[],
    sweep_status_id integer DEFAULT '-1'::integer NOT NULL,
    "UUID" character varying(50) DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE helper OWNER TO carpool_admins;

--
-- Name: match; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE match (
    status character varying(30) DEFAULT 'Proposed'::character varying NOT NULL,
    uuid_driver character varying(50) NOT NULL,
    uuid_rider character varying(50) NOT NULL,
    score smallint DEFAULT 0 NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


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
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    status character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    recipient character varying(15) NOT NULL,
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
    "RiderCollectionAddress" character varying(1000),
    "RiderDestinationAddress" character varying(1000)
);


ALTER TABLE rider OWNER TO carpool_admins;

--
-- Name: tz_dst_offset; Type: TABLE; Schema: carpoolvote; Owner: eric
--

CREATE TABLE tz_dst_offset (
    timezone text NOT NULL,
    observes_dst character varying(50),
    offset_summer integer,
    offset_fall integer
);


ALTER TABLE tz_dst_offset OWNER TO eric;

--
-- Name: usstate; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE usstate (
    stateabbrev character(2) NOT NULL,
    statename character varying(50)
);


ALTER TABLE usstate OWNER TO carpool_admins;

--
-- Name: vw_drive_offer; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_drive_offer AS
 SELECT driver."UUID",
    driver."DriverLastName",
    driver."DriverPhone",
    driver."DriverEmail",
    driver.status,
    driver.status_info,
    driver.created_ts,
    driver.last_updated_ts,
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."DriverCanLoadRiderWithWheelchair",
    driver."SeatCount",
    driver."DrivingOnBehalfOfOrganization",
    driver."AvailableDriveTimesLocal"
   FROM driver;


ALTER TABLE vw_drive_offer OWNER TO carpool_admins;

--
-- Name: vw_driver_matches; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_driver_matches AS
 SELECT match.status AS "matchStatus",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
    rider."UUID",
    rider."IPAddress",
    rider."RiderFirstName",
    rider."RiderLastName",
    rider."RiderEmail",
    rider."RiderPhone",
    rider."RiderCollectionZIP",
    rider."RiderDropOffZIP",
    rider."AvailableRideTimesLocal",
    rider."TotalPartySize",
    rider."TwoWayTripNeeded",
    rider."RiderIsVulnerable",
    rider."RiderWillNotTalkPolitics",
    rider."PleaseStayInTouch",
    rider."NeedWheelchair",
    rider."RiderPreferredContact",
    rider."RiderAccommodationNotes",
    rider."RiderLegalConsent",
    rider."ReadyToMatch",
    rider.status,
    rider.status_info,
    rider."RiderWillBeSafe",
    rider."RiderCollectionAddress",
    rider."RiderDestinationAddress"
   FROM (match
     JOIN rider ON (((rider."UUID")::text = (match.uuid_rider)::text)));


ALTER TABLE vw_driver_matches OWNER TO carpool_admins;

--
-- Name: vw_ride_request; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_ride_request AS
 SELECT rider."UUID" AS uuid,
    rider."RiderLastName",
    rider."RiderPhone",
    rider."RiderEmail",
    rider.status,
    rider.status_info,
    rider.created_ts,
    rider.last_updated_ts,
    rider."RiderCollectionZIP",
    rider."RiderDropOffZIP",
    rider."TotalPartySize",
    rider."RiderIsVulnerable",
    rider."NeedWheelchair",
    rider."AvailableRideTimesLocal"
   FROM rider;


ALTER TABLE vw_ride_request OWNER TO carpool_admins;

--
-- Name: vw_rider_matches; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_rider_matches AS
 SELECT match.status AS "matchStatus",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
    driver."UUID",
    driver."IPAddress",
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."AvailableDriveTimesLocal",
    driver."DriverCanLoadRiderWithWheelchair",
    driver."SeatCount",
    driver."DriverLicenseNumber",
    driver."DriverFirstName",
    driver."DriverLastName",
    driver."DriverEmail",
    driver."DriverPhone",
    driver."DrivingOnBehalfOfOrganization",
    driver."DrivingOBOOrganizationName",
    driver."RidersCanSeeDriverDetails",
    driver."DriverWillNotTalkPolitics",
    driver."ReadyToMatch",
    driver."PleaseStayInTouch",
    driver.status,
    driver.status_info,
    driver."DriverPreferredContact",
    driver."DriverWillTakeCare"
   FROM (match
     JOIN driver ON (((driver."UUID")::text = (match.uuid_driver)::text)));


ALTER TABLE vw_rider_matches OWNER TO carpool_admins;

--
-- Name: vw_unmatched_drivers; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE vw_unmatched_drivers (
    count bigint,
    zip character varying(5),
    state character(2),
    city character varying(50),
    full_state character varying(50),
    latitude_numeric real,
    longitude_numeric real
);

ALTER TABLE ONLY vw_unmatched_drivers REPLICA IDENTITY NOTHING;


ALTER TABLE vw_unmatched_drivers OWNER TO carpool_admins;

--
-- Name: vw_unmatched_drivers_details; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_unmatched_drivers_details AS
 SELECT driver."UUID",
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."SeatCount",
    driver."AvailableDriveTimesLocal"
   FROM driver
  WHERE (((driver.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text, ('MatchConfirmed'::character varying)::text])) AND (driver."ReadyToMatch" = true));


ALTER TABLE vw_unmatched_drivers_details OWNER TO carpool_admins;

--
-- Name: vw_unmatched_riders; Type: TABLE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TABLE vw_unmatched_riders (
    count bigint,
    zip character varying(5),
    state character(2),
    city character varying(50),
    full_state character varying(50),
    latitude_numeric real,
    longitude_numeric real
);

ALTER TABLE ONLY vw_unmatched_riders REPLICA IDENTITY NOTHING;


ALTER TABLE vw_unmatched_riders OWNER TO carpool_admins;

--
-- Name: vw_unmatched_riders_details; Type: VIEW; Schema: carpoolvote; Owner: carpool_admins
--

CREATE VIEW vw_unmatched_riders_details AS
 SELECT rider."UUID",
    rider."RiderCollectionZIP",
    rider."TotalPartySize",
    rider."NeedWheelchair",
    rider."AvailableRideTimesLocal"
   FROM rider
  WHERE ((rider.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text]));


ALTER TABLE vw_unmatched_riders_details OWNER TO carpool_admins;

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
    ADD CONSTRAINT match_pkey PRIMARY KEY (uuid_driver, uuid_rider, score);


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
-- Name: tz_dst_offset_pkey; Type: CONSTRAINT; Schema: carpoolvote; Owner: eric
--

ALTER TABLE ONLY tz_dst_offset
    ADD CONSTRAINT tz_dst_offset_pkey PRIMARY KEY (timezone);


--
-- Name: _RETURN; Type: RULE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE RULE "_RETURN" AS
    ON SELECT TO vw_unmatched_drivers DO INSTEAD  SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM driver driver,
    zip_codes zip_codes
  WHERE (((driver.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text])) AND ((driver."DriverCollectionZIP")::text = (zip_codes.zip)::text))
  GROUP BY zip_codes.zip;


--
-- Name: _RETURN; Type: RULE; Schema: carpoolvote; Owner: carpool_admins
--

CREATE RULE "_RETURN" AS
    ON SELECT TO vw_unmatched_riders DO INSTEAD  SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM rider rider,
    zip_codes zip_codes
  WHERE (((rider.status)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text])) AND ((rider."RiderCollectionZIP")::text = (zip_codes.zip)::text))
  GROUP BY zip_codes.zip;


--
-- Name: send_email_notif_ins_driver_trg; Type: TRIGGER; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TRIGGER send_email_notif_ins_driver_trg AFTER INSERT ON driver FOR EACH ROW EXECUTE PROCEDURE queue_email_notif();


--
-- Name: send_email_notif_ins_rider_trg; Type: TRIGGER; Schema: carpoolvote; Owner: carpool_admins
--

CREATE TRIGGER send_email_notif_ins_rider_trg AFTER INSERT ON rider FOR EACH ROW EXECUTE PROCEDURE queue_email_notif();


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
-- Name: carpoolvote; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA carpoolvote FROM PUBLIC;
REVOKE ALL ON SCHEMA carpoolvote FROM postgres;
GRANT ALL ON SCHEMA carpoolvote TO postgres;
GRANT USAGE ON SCHEMA carpoolvote TO carpool_role;
GRANT ALL ON SCHEMA carpoolvote TO carpool_admins;
GRANT USAGE ON SCHEMA carpoolvote TO carpool_web_role;


--
-- Name: distance(double precision, double precision, double precision, double precision); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM PUBLIC;
REVOKE ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM carpool_admins;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_admins;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO PUBLIC;
GRANT ALL ON FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_role;


--
-- Name: driver_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_cancel_drive_offer(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_confirm_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_confirmed_matches(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_exists(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_info(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_pause_match(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_proposed_matches(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: evaluate_match_single_pair(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) TO carpool_admins;
GRANT ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) TO PUBLIC;
GRANT ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) TO carpool_role;


--
-- Name: fct_modified_column(); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION fct_modified_column() FROM PUBLIC;
REVOKE ALL ON FUNCTION fct_modified_column() FROM carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_role;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_web_role;


--
-- Name: get_param_value(character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION get_param_value(a_param_name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_param_value(a_param_name character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO carpool_admins;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO carpool_web;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO carpool_role;


--
-- Name: perform_match(); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION perform_match() FROM PUBLIC;
REVOKE ALL ON FUNCTION perform_match() FROM carpool_admins;
GRANT ALL ON FUNCTION perform_match() TO carpool_admins;
GRANT ALL ON FUNCTION perform_match() TO carpool_role;
GRANT ALL ON FUNCTION perform_match() TO PUBLIC;


--
-- Name: rider_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: rider_cancel_ride_request(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: rider_confirmed_match(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_exists(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_info(character varying, character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: update_drive_offer_status(character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) TO carpool_admins;
GRANT ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) TO PUBLIC;
GRANT ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) TO carpool_web;
GRANT ALL ON FUNCTION update_drive_offer_status(a_uuid character varying) TO carpool_role;


--
-- Name: update_ride_request_status(character varying); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION update_ride_request_status(a_uuid character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_ride_request_status(a_uuid character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION update_ride_request_status(a_uuid character varying) TO carpool_admins;
GRANT ALL ON FUNCTION update_ride_request_status(a_uuid character varying) TO PUBLIC;
GRANT ALL ON FUNCTION update_ride_request_status(a_uuid character varying) TO carpool_web;
GRANT ALL ON FUNCTION update_ride_request_status(a_uuid character varying) TO carpool_role;


--
-- Name: urlencode(text); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION urlencode(in_str text, OUT _result text) FROM PUBLIC;
REVOKE ALL ON FUNCTION urlencode(in_str text, OUT _result text) FROM carpool_admins;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO carpool_admins;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO PUBLIC;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO carpool_role;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO carpool_web_role;


--
-- Name: driver; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE driver FROM PUBLIC;
REVOKE ALL ON TABLE driver FROM carpool_admins;
GRANT ALL ON TABLE driver TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE driver TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE driver TO carpool_role;


--
-- Name: driver.UUID; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL("UUID") ON TABLE driver FROM PUBLIC;
REVOKE ALL("UUID") ON TABLE driver FROM carpool_admins;
GRANT SELECT("UUID") ON TABLE driver TO carpool_web;


--
-- Name: helper; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE helper FROM PUBLIC;
REVOKE ALL ON TABLE helper FROM carpool_admins;
GRANT ALL ON TABLE helper TO carpool_admins;
GRANT INSERT ON TABLE helper TO carpool_web_role;
GRANT ALL ON TABLE helper TO carpool_role;


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
REVOKE ALL ON TABLE params FROM carpool_admins;
GRANT ALL ON TABLE params TO carpool_admins;
GRANT SELECT ON TABLE params TO carpool_role;
GRANT SELECT ON TABLE params TO carpool_web_role;


--
-- Name: rider; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE rider FROM PUBLIC;
REVOKE ALL ON TABLE rider FROM carpool_admins;
GRANT ALL ON TABLE rider TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE rider TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE rider TO carpool_role;


--
-- Name: rider.UUID; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL("UUID") ON TABLE rider FROM PUBLIC;
REVOKE ALL("UUID") ON TABLE rider FROM carpool_admins;
GRANT SELECT("UUID") ON TABLE rider TO carpool_web;


--
-- Name: vw_drive_offer; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_drive_offer FROM PUBLIC;
REVOKE ALL ON TABLE vw_drive_offer FROM carpool_admins;
GRANT ALL ON TABLE vw_drive_offer TO carpool_admins;
GRANT SELECT ON TABLE vw_drive_offer TO carpool_role;


--
-- Name: vw_driver_matches; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_driver_matches FROM PUBLIC;
REVOKE ALL ON TABLE vw_driver_matches FROM carpool_admins;
GRANT ALL ON TABLE vw_driver_matches TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE vw_driver_matches TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_driver_matches TO carpool_role;
GRANT SELECT ON TABLE vw_driver_matches TO carpool_web;


--
-- Name: vw_ride_request; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_ride_request FROM PUBLIC;
REVOKE ALL ON TABLE vw_ride_request FROM carpool_admins;
GRANT ALL ON TABLE vw_ride_request TO carpool_admins;
GRANT SELECT ON TABLE vw_ride_request TO carpool_role;


--
-- Name: vw_rider_matches; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_rider_matches FROM PUBLIC;
REVOKE ALL ON TABLE vw_rider_matches FROM carpool_admins;
GRANT ALL ON TABLE vw_rider_matches TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE vw_rider_matches TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_rider_matches TO carpool_role;
GRANT SELECT ON TABLE vw_rider_matches TO carpool_web;


--
-- Name: vw_unmatched_drivers; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_drivers FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_drivers FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_drivers TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_drivers TO carpool_web_role;
GRANT SELECT ON TABLE vw_unmatched_drivers TO carpool_role;


--
-- Name: vw_unmatched_drivers_details; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_drivers_details FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_drivers_details FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_drivers_details TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_drivers_details TO carpool_role;
GRANT SELECT ON TABLE vw_unmatched_drivers_details TO carpool_web;
GRANT SELECT ON TABLE vw_unmatched_drivers_details TO carpool_web_role;


--
-- Name: vw_unmatched_riders; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_riders FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_riders FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_riders TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_riders TO carpool_web_role;
GRANT SELECT ON TABLE vw_unmatched_riders TO carpool_role;


--
-- Name: vw_unmatched_riders_details; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_riders_details FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_riders_details FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_riders_details TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_riders_details TO carpool_role;
GRANT SELECT ON TABLE vw_unmatched_riders_details TO carpool_web;
GRANT SELECT ON TABLE vw_unmatched_riders_details TO carpool_web_role;


--
-- Name: zip_codes; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON TABLE zip_codes FROM PUBLIC;
REVOKE ALL ON TABLE zip_codes FROM carpool_admins;
GRANT ALL ON TABLE zip_codes TO carpool_admins;
GRANT ALL ON TABLE zip_codes TO carpool_role;


--
-- PostgreSQL database dump complete
--

