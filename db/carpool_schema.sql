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
-- Name: import; Type: SCHEMA; Schema: -; Owner: eric
--

CREATE SCHEMA import;


ALTER SCHEMA import OWNER TO eric;

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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
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
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" 
			|| '&UUID_rider=' || a_UUID_rider 
			|| '&Score=' || a_score 
			|| '">Self-Service Portal</a></p>'
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" 
			|| '&UUID_driver=' || a_UUID_driver 
			|| '&Score=' || a_score 
			|| '">Self-Service Portal</a></p>'
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

$$;


ALTER FUNCTION nov2016.driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_confirmed_matches(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) RETURNS SETOF json
    LANGUAGE sql STABLE
    AS $$

-- DECLARE                                                   

-- BEGIN 

	-- input validation
	-- IF NOT EXISTS (
	-- SELECT 1 
	-- FROM stage.websubmission_driver r
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
    --         nov2016.vw_driver_matches
    --     WHERE
    --             uuid_driver = a_uuid
    --         AND "matchState" = 'MatchConfirmed';
    --         -- AND "matchState" = 'Canceled';

    --    RETURN row_to_json(d_row);

        SELECT row_to_json(s)
        FROM ( 
            SELECT * from
            nov2016.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchState" = 'MatchConfirmed'
        ) s ;

-- END  

$$;


ALTER FUNCTION nov2016.driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_exists(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

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

	return '';
	
END  

$$;


ALTER FUNCTION nov2016.driver_exists(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_info(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	v_step character varying(200); 
	v_return_text character varying(200);	
	d_row stage.websubmission_driver%ROWTYPE;
	
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
		-- return 'No Drive Offer found for those parameters';
       RETURN row_to_json(d_row);
	END IF;

       SELECT * INTO
           d_row
       FROM
           stage.websubmission_driver
       WHERE
           "UUID" = a_uuid;

       RETURN row_to_json(d_row);
	
END  

$$;


ALTER FUNCTION nov2016.driver_info(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_pause_match(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

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

$$;


ALTER FUNCTION nov2016.driver_pause_match(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: driver_proposed_matches(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) RETURNS SETOF json
    LANGUAGE sql STABLE
    AS $$

-- DECLARE                                                   
--BEGIN 

        SELECT row_to_json(s)
        FROM ( 
            SELECT * from
            nov2016.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchState" = 'MatchProposed'
        ) s ;

--END  

$$;


ALTER FUNCTION nov2016.driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: evaluate_match_single_pair(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE

run_now nov2016.match_engine_scheduler.need_run_flag%TYPE;

v_start_ts nov2016.match_engine_activity_log.start_ts%TYPE;
v_end_ts nov2016.match_engine_activity_log.end_ts%TYPE;
v_evaluated_pairs nov2016.match_engine_activity_log.evaluated_pairs%TYPE;
v_proposed_count nov2016.match_engine_activity_log.proposed_count%TYPE;
v_error_count nov2016.match_engine_activity_log.error_count%TYPE;
v_expired_count nov2016.match_engine_activity_log.expired_count%TYPE;

b_rider_all_times_expired  boolean := TRUE;
b_rider_validated boolean := TRUE;
b_driver_all_times_expired boolean := TRUE;
b_driver_validated boolean := TRUE;

RADIUS_MAX_ALLOWED integer := 100;

drive_offer_row stage.websubmission_driver%ROWTYPE;
ride_request_row stage.websubmission_rider%ROWTYPE;
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

zip_origin nov2016.zip_codes%ROWTYPE;  -- Driver's origin
zip_pickup nov2016.zip_codes%ROWTYPE;  -- Rider's pickup
zip_dropoff nov2016.zip_codes%ROWTYPE; -- Rider's dropoff

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
	--	INSERT INTO nov2016.match_engine_scheduler VALUES(true);
	--EXCEPTION WHEN OTHERS
	--THEN
		-- ignore
	--END;
	--SELECT need_run_flag INTO run_now from nov2016.match_engine_scheduler LIMIT 1;
	IF run_now
	THEN

		
	
		-- Initialize Counters
		v_start_ts := now();
		v_evaluated_pairs := 0;
		v_proposed_count := 0;
		v_error_count := 0;
		v_expired_count := 0;

		
		
		FOR ride_request_row in SELECT * from stage.websubmission_rider r
			WHERE r.state in ('Pending','MatchProposed') AND r."UUID" like arg_uuid_rider || '%'
		LOOP
		
			IF length(ride_request_row."AvailableRideTimesUTC") = 0
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Invalid AvailableRideTimes'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;
			

			BEGIN
				-- DriverCollectionZIP
				-- DriverCollectionRadius
			
				SELECT * INTO zip_pickup FROM nov2016.zip_codes WHERE zip=ride_request_row."RiderCollectionZIP";
				SELECT * INTO zip_dropoff FROM nov2016.zip_codes WHERE zip=ride_request_row."RiderDropOffZIP";
			
			EXCEPTION WHEN OTHERS
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Unknown/Invalid RiderCollectionZIP or RiderDropOffZIP'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END;
			
			IF ride_request_row."TotalPartySize" = 0
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Invalid TotalPartySize'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;
	
	
			-- split AvailableRideTimesUTC in individual time intervals
			ride_times_rider := string_to_array(ride_request_row."AvailableRideTimesUTC", '|');
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
						UPDATE stage.websubmission_rider 
						SET state='Failed', state_info='Invalid value in AvailableRideTimes:' || rider_time
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
					UPDATE stage.websubmission_rider
					SET state='Failed', state_info='Invalid value in AvailableRideTimes:' || rider_time
					WHERE "UUID"=ride_request_row."UUID";

					b_rider_validated := FALSE;
				END;
				
				IF b_rider_all_times_expired
				THEN
					UPDATE stage.websubmission_rider r
					SET state='Expired', state_info='All AvailableRideTimes are expired'
					WHERE "UUID"=ride_request_row."UUID";

					v_expired_count := v_expired_count +1;
					
					b_rider_validated := FALSE;
				END IF;
				
			END LOOP;
	
			IF b_rider_validated
			THEN
			
 				FOR drive_offer_row in SELECT * from stage.websubmission_driver d
 					WHERE state IN ('Pending','MatchProposed','MatchConfirmed')
 					AND ((ride_request_row."NeedWheelchair"=true AND d."DriverCanLoadRiderWithWheelchair" = true) -- driver must be able to transport wheelchair if rider needs it
 						OR ride_request_row."NeedWheelchair"=false)   -- but a driver equipped for wheelchair may drive someone who does not need one
 					AND ride_request_row."TotalPartySize" <= d."SeatCount"  -- driver must be able to accommodate the entire party in one ride

 				LOOP
 
 					IF length(drive_offer_row."AvailableDriveTimesUTC") = 0
 					THEN
 						UPDATE stage.websubmission_driver 
 						SET state='Failed', state_info='Invalid AvailableDriveTimes'
 						WHERE "UUID"=drive_offer_row."UUID";
 				
 						b_driver_validated := false;
 					END IF;
 
 					BEGIN
 						SELECT * INTO zip_origin FROM nov2016.zip_codes WHERE zip=drive_offer_row."DriverCollectionZIP";
 					EXCEPTION WHEN OTHERS
 					THEN
 						UPDATE stage.websubmission_driver 
 						SET state='Failed', state_info='Invalid DriverCollectionZIP'
 						WHERE "UUID"=drive_offer_row."UUID";
 					
 						b_driver_validated := FALSE;
 					END;
 					
 					
 					-- split AvailableDriveTimesUTC in individual time intervals
 					-- NOTE : we do not want actual JSON here...
 					-- FORMAT should be like this 
 					-- 2016-10-01T08:00:00-0500/2016-10-01T10:00:00-0500|2016-10-01T10:00:00-0500/2016-10-01T22:00:00-0500|2016-10-01T22:00:00-0500/2016-10-01T23:00:00-0500
 					ride_times_driver := string_to_array(drive_offer_row."AvailableDriveTimesUTC", '|');
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
								UPDATE stage.websubmission_driver 
								SET state='Failed', state_info='Invalid value in AvailableDriveTimes:' || driver_time
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
							UPDATE stage.websubmission_driver 
							SET state='Failed', state_info='Invalid value in AvailableDriveTimes :' || driver_time
							WHERE "UUID"=drive_offer_row."UUID";

							b_driver_validated := FALSE;
						END;
		
		
						IF b_driver_all_times_expired
						THEN
							UPDATE stage.websubmission_driver
							SET state='Expired', state_info='All AvailableDriveTimes are expired'
							WHERE "UUID"=drive_offer_row."UUID";

							v_expired_count := v_expired_count +1;
					
							b_driver_validated := FALSE;
						END IF;
				
					END LOOP;		
					IF 	b_driver_validated
					THEN
				
						match_points := 0;
				
						-- Compare RiderCollectionZIP with DriverCollectionZIP / DriverCollectionRadius
						distance_origin_pickup := nov2016.distance(
									zip_origin.latitude_numeric,
									zip_origin.longitude_numeric,
									zip_pickup.latitude_numeric,
									zip_pickup.longitude_numeric);
						
						distance_origin_dropoff := nov2016.distance(
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

											
											-- The state of the ride request is 
											
											UPDATE stage.websubmission_rider r
											SET state='MatchProposed'
											WHERE r."UUID" = ride_request_row."UUID";

											-- If already MatchConfirmed, keep it as is
											IF drive_offer_row.state = 'Pending'
											THEN
												UPDATE stage.websubmission_driver d
												SET state='MatchProposed'
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
		--INSERT INTO nov2016.match_engine_activity_log (
				--start_ts, end_ts , evaluated_pairs,
				--proposed_count, error_count, expired_count)
		--VALUES(v_start_ts, v_end_ts, v_evaluated_pairs,
				--v_proposed_count, v_error_count, v_expired_count);
		
		-- Update scheduler
		-- UPDATE nov2016.match_engine_scheduler set need_run_flag = false;
		
		
		
	END IF;
	
	return '';
END
$$;


ALTER FUNCTION nov2016.evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) OWNER TO carpool_admins;

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
-- Name: get_param_value(character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION get_param_value(a_param_name character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION nov2016.get_param_value(a_param_name character varying) OWNER TO carpool_admins;

--
-- Name: perform_match(); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION perform_match() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE

run_now nov2016.match_engine_scheduler.need_run_flag%TYPE;

v_start_ts nov2016.match_engine_activity_log.start_ts%TYPE;
v_end_ts nov2016.match_engine_activity_log.end_ts%TYPE;
v_evaluated_pairs nov2016.match_engine_activity_log.evaluated_pairs%TYPE;
v_proposed_count nov2016.match_engine_activity_log.proposed_count%TYPE;
v_error_count nov2016.match_engine_activity_log.error_count%TYPE;
v_expired_count nov2016.match_engine_activity_log.expired_count%TYPE;

b_rider_all_times_expired  boolean := TRUE;
b_rider_validated boolean := TRUE;
b_driver_all_times_expired boolean := TRUE;
b_driver_validated boolean := TRUE;

RADIUS_MAX_ALLOWED integer := 100;
BEYOND_RADIUS_TOLERANCE integer := 20;

drive_offer_row stage.websubmission_driver%ROWTYPE;
ride_request_row stage.websubmission_rider%ROWTYPE;
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

zip_origin nov2016.zip_codes%ROWTYPE;  -- Driver's origin
zip_pickup nov2016.zip_codes%ROWTYPE;  -- Rider's pickup
zip_dropoff nov2016.zip_codes%ROWTYPE; -- Rider's dropoff

distance_origin_pickup double precision;  -- From driver origin to rider pickup point
distance_origin_dropoff double precision; -- From driver origin to rider drop off point

g_uuid_driver character varying(50);
g_uuid_rider  character varying(50);
g_record record;
g_email_body text;
g_sms_body text;

v_subject nov2016.outgoing_email.subject%TYPE;                                                                            
v_body nov2016.outgoing_email.body%TYPE;                                                                                  
v_html_header nov2016.outgoing_email.body%TYPE;
v_html_body   nov2016.outgoing_email.body%TYPE;
v_html_footer nov2016.outgoing_email.body%TYPE;

v_loop_cnt integer;
v_row_style text;

BEGIN

	run_now := true;
	--BEGIN
	--	INSERT INTO nov2016.match_engine_scheduler VALUES(true);
	--EXCEPTION WHEN OTHERS
	--THEN
		-- ignore
	--END;
	--SELECT need_run_flag INTO run_now from nov2016.match_engine_scheduler LIMIT 1;
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

		
		
		FOR ride_request_row in SELECT * from stage.websubmission_rider r
			WHERE r.state in ('Pending','MatchProposed')
		LOOP
		
			IF length(ride_request_row."AvailableRideTimesLocal") = 0
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Invalid AvailableRideTimes'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;
			

			BEGIN
				-- DriverCollectionZIP
				-- DriverCollectionRadius
			
				SELECT * INTO zip_pickup FROM nov2016.zip_codes WHERE zip=ride_request_row."RiderCollectionZIP";
				SELECT * INTO zip_dropoff FROM nov2016.zip_codes WHERE zip=ride_request_row."RiderDropOffZIP";
			
			EXCEPTION WHEN OTHERS
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Unknown/Invalid RiderCollectionZIP or RiderDropOffZIP'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END;
			
			IF ride_request_row."TotalPartySize" = 0
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Invalid TotalPartySize'
				WHERE "UUID"=ride_request_row."UUID";
				
				b_rider_validated := FALSE;
			END IF;

            -- zip code verification
			IF NOT EXISTS
				(SELECT 1 FROM nov2016.zip_codes z where z.zip = ride_request_row."RiderCollectionZIP" AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Invalid/Not Found RiderCollectionZIP:' || ride_request_row."RiderCollectionZIP"
				WHERE "UUID"=ride_request_row."UUID";
				b_rider_validated := FALSE;
			END IF;

			IF NOT EXISTS 
				(SELECT 1 FROM nov2016.zip_codes z WHERE z.zip = ride_request_row."RiderDropOffZIP" AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
			THEN
				UPDATE stage.websubmission_rider 
				SET state='Failed', state_info='Invalid/Not Found RiderDropOffZIP:' || ride_request_row."RiderDropOffZIP"
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
						UPDATE stage.websubmission_rider 
						SET state='Failed', state_info='Invalid value in AvailableRideTimes:' || rider_time
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
					UPDATE stage.websubmission_rider
					SET state='Failed', state_info='Invalid value in AvailableRideTimes:' || rider_time
					WHERE "UUID"=ride_request_row."UUID";

					b_rider_validated := FALSE;
				END;
				
				IF b_rider_all_times_expired
				THEN
					UPDATE stage.websubmission_rider r
					SET state='Expired', state_info='All AvailableRideTimes are expired'
					WHERE "UUID"=ride_request_row."UUID";

					v_expired_count := v_expired_count +1;
					
					b_rider_validated := FALSE;
				END IF;
								
			END LOOP;
	
			IF b_rider_validated
			THEN
			
 				FOR drive_offer_row in SELECT * from stage.websubmission_driver d
 					WHERE state IN ('Pending','MatchProposed','MatchConfirmed')
					AND d."ReadyToMatch" = true
 					AND ((ride_request_row."NeedWheelchair"=true AND d."DriverCanLoadRiderWithWheelchair" = true) -- driver must be able to transport wheelchair if rider needs it
 						OR ride_request_row."NeedWheelchair"=false)   -- but a driver equipped for wheelchair may drive someone who does not need one
 					AND ride_request_row."TotalPartySize" <= d."SeatCount"  -- driver must be able to accommodate the entire party in one ride
                    
 				LOOP
                    IF EXISTS (SELECT 1 FROM nov2016.match
                                    WHERE uuid_driver = drive_offer_row."UUID" and uuid_rider = ride_request_row."UUID")
                    THEN
                        CONTINUE;  -- skip evaluating this pair since there is already a match
                    END IF;
                    
 					IF length(drive_offer_row."AvailableDriveTimesLocal") = 0
 					THEN
 						UPDATE stage.websubmission_driver 
 						SET state='Failed', state_info='Invalid AvailableDriveTimes'
 						WHERE "UUID"=drive_offer_row."UUID";
 				
 						b_driver_validated := false;
 					END IF;
 
					IF NOT EXISTS 
						(SELECT 1 FROM nov2016.zip_codes z where z.zip = drive_offer_row."DriverCollectionZIP" AND z.latitude_numeric IS NOT NULL AND z.longitude_numeric IS NOT NULL)
					THEN
						UPDATE stage.websubmission_driver 
						SET state='Failed', state_info='Invalid/Not Found DriverCollectionZIP:' || drive_offer_row."DriverCollectionZIP"
						WHERE "UUID"=drive_offer_row."UUID";
						b_driver_validated := FALSE;
					END IF; 	
 
 					BEGIN
 						SELECT * INTO zip_origin FROM nov2016.zip_codes WHERE zip=drive_offer_row."DriverCollectionZIP";
 					EXCEPTION WHEN OTHERS
 					THEN
 						UPDATE stage.websubmission_driver 
 						SET state='Failed', state_info='Invalid DriverCollectionZIP'
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
								UPDATE stage.websubmission_driver 
								SET state='Failed', state_info='Invalid value in AvailableDriveTimes:' || driver_time
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
							UPDATE stage.websubmission_driver 
							SET state='Failed', state_info='Invalid value in AvailableDriveTimes :' || driver_time
							WHERE "UUID"=drive_offer_row."UUID";

							b_driver_validated := FALSE;
						END;
		
		
						IF b_driver_all_times_expired
						THEN
							UPDATE stage.websubmission_driver
							SET state='Expired', state_info='All AvailableDriveTimes are expired'
							WHERE "UUID"=drive_offer_row."UUID";

							v_expired_count := v_expired_count +1;
					
							b_driver_validated := FALSE;
						END IF;
				
					END LOOP;		
					IF 	b_driver_validated
					THEN
				
						match_points := 0;
				
						-- Compare RiderCollectionZIP with DriverCollectionZIP / DriverCollectionRadius
						distance_origin_pickup := nov2016.distance(
									zip_origin.latitude_numeric,
									zip_origin.longitude_numeric,
									zip_pickup.latitude_numeric,
									zip_pickup.longitude_numeric);
						
						distance_origin_dropoff := nov2016.distance(
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
                                                UPDATE nov2016.match
                                                SET score = match_points_with_time
                                                WHERE uuid_rider = ride_request_row."UUID"
                                                AND uuid_driver = drive_offer_row."UUID"
                                                AND score < match_points_with_time;
                                                
                                                RAISE NOTICE 'Better Proposed Match, Rider=%, Driver=%, Score=%',
														ride_request_row."UUID", drive_offer_row."UUID", match_points_with_time;
                                                
                                            END IF;
                                        
                                        ELSE
											INSERT INTO nov2016.match (uuid_rider, uuid_driver, score, state)
												VALUES (
													ride_request_row."UUID",               --pkey
													drive_offer_row."UUID",                --pkey 
													match_points_with_time,                --pkey
													'MatchProposed'
												);

											INSERT INTO match_notifications_buffer (uuid_driver, uuid_rider, score)
                                                VALUES (drive_offer_row."UUID", ride_request_row."UUID", match_points_with_time);
																						
											UPDATE stage.websubmission_rider r
											SET state='MatchProposed'
											WHERE r."UUID" = ride_request_row."UUID";

											-- If already MatchConfirmed, keep it as is
											UPDATE stage.websubmission_driver d
												SET state='MatchProposed'
												WHERE d."UUID" = drive_offer_row."UUID"
                                                AND state='Pending';
											
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
		FOR drive_offer_row IN SELECT * FROM stage.websubmission_driver d
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
			FOR g_record IN SELECT * FROM nov2016.match m 
									WHERE m.uuid_driver = drive_offer_row."UUID" order by score desc
			LOOP
                v_row_style := CASE WHEN v_loop_cnt % 2 =1 THEN 'oddRow' else 'evenRow' END;
					
				SELECT * INTO ride_request_row FROM stage.websubmission_rider r
												WHERE r."UUID" = g_record.uuid_rider;

				v_html_body := v_html_body 
                    || '<tr>' 
                    || '<td class="' || v_row_style || '">' ||
                        CASE WHEN g_record.state='MatchProposed' THEN '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/accept-driver-match' 
                            || '?UUID_driver=' || drive_offer_row."UUID"
                            || '&UUID_rider=' || g_record.uuid_rider
                            || '&Score=' || g_record.score
                            || '&DriverPhone=' || nov2016.urlencode(drive_offer_row."DriverLastName" )   -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
                            || '">Accept</a>'
                        ELSE g_record.state END || '</td>'
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
				|| '<p>If you do not with to receive future notifications about new proposed matches for this Driver Offer, please <a href="' || 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/pause-match-driver?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || nov2016.urlencode(drive_offer_row."DriverLastName") ||  '">click here</a></p>'            
                || '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || drive_offer_row."UUID" || '&DriverPhone=' || nov2016.urlencode(drive_offer_row."DriverLastName") ||  '">Cancel your Drive Offer</a></p>'
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
				INSERT INTO nov2016.outgoing_email (recipient, subject, body)
				VALUES (drive_offer_row."DriverEmail", 
				'Proposed rider match update!   --- [' || drive_offer_row."UUID" || ']', 
				v_body);
				
			END IF;
				
			IF drive_offer_row."DriverPhone" IS NOT NULL AND (position('SMS' in drive_offer_row."DriverPreferredContact") > 0)
			THEN
			
				g_sms_body := 'From CarpoolVote.com\n' 
						|| 'New matches are available.\n'
				        || 'Visit the self-service page for details http://carpoolvote.com/self-service/?type=driver&uuid=' || drive_offer_row."UUID";			
			
				INSERT INTO nov2016.outgoing_sms (recipient, body)
				VALUES (drive_offer_row."DriverPhone", 
				g_sms_body);
			
			END IF;

			
		END LOOP;
		

		
		v_end_ts := now();
		-- Update activity log
		INSERT INTO nov2016.match_engine_activity_log (
				start_ts, end_ts , evaluated_pairs,
				proposed_count, error_count, expired_count)
		VALUES(v_start_ts, v_end_ts, v_evaluated_pairs,
				v_proposed_count, v_error_count, v_expired_count);
		
		-- Update scheduler
		-- UPDATE nov2016.match_engine_scheduler set need_run_flag = false;
		
		
		
	END IF;
	
	return '';
END
$$;


ALTER FUNCTION nov2016.perform_match() OWNER TO carpool_admins;

--
-- Name: queue_email_notif(); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION queue_email_notif() RETURNS trigger
    LANGUAGE plpgsql
    AS $$                                                                                                                  
DECLARE                                                                                                                    
 
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

    -- triggered by submitting a drive offer form                                                                          
    IF TG_TABLE_NAME = 'websubmission_driver' and TG_TABLE_SCHEMA='stage'                                                  
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
			|| '<p><a href="'|| 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || NEW."UUID" || '&DriverPhone=' || nov2016.urlencode(NEW."DriverLastName") ||  '">Cancel this offer</a></p>'  -- yes, this is correct, the API uses DriverPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;


            INSERT INTO nov2016.outgoing_email (recipient, subject, body)                                             
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
--					|| 'Cancel : https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || NEW."UUID" || '&DriverPhone=' || nov2016.urlencode(NEW."DriverLastName");
					
            INSERT INTO nov2016.outgoing_sms (recipient, body)                                             
            VALUES (NEW."DriverPhone", v_body);                                                                 
        END IF;                                                                                                            
		
    -- triggered by submitting a ride request form                                                                         
    ELSIF TG_TABLE_NAME = 'websubmission_rider' and TG_TABLE_SCHEMA='stage'                                                
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
			|| '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || NEW."UUID" || '&RiderPhone=' || nov2016.urlencode(NEW."RiderLastName") ||  '">Cancel this request</a></p>' -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;
            INSERT INTO nov2016.outgoing_email (recipient, subject, body)                                             
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
					|| 'Cancel : https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || NEW."UUID" || '&RiderPhone=' || nov2016.urlencode(NEW."RiderLastName");
				
            INSERT INTO nov2016.outgoing_sms (recipient, body)                                             
            VALUES (NEW."RiderPhone", v_body);                                                                 
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
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_rider=' || ride_request_row."UUID" || '">Self-Service Portal</a></p>'
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
				|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?UUID_driver=' || drive_offer_row."UUID" || '">Self-Service Portal</a></p>'
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

$$;


ALTER FUNCTION nov2016.rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_confirmed_match(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$

DECLARE                                                   
	r_row nov2016.vw_rider_matches%ROWTYPE;

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
        RETURN row_to_json(r_row);
	END IF;

        SELECT * INTO
            r_row
        FROM
            nov2016.vw_rider_matches
        WHERE
                uuid_rider = a_uuid
            AND "matchState" = 'MatchConfirmed';
            -- AND "matchState" = 'Canceled';

       RETURN row_to_json(r_row);

END  

$$;


ALTER FUNCTION nov2016.rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_exists(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

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
	FROM stage.websubmission_rider r
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


ALTER FUNCTION nov2016.rider_exists(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

--
-- Name: rider_info(character varying, character varying); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
--

CREATE FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$

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
	r_row stage.websubmission_rider%ROWTYPE;

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
		-- return 'No Ride Request found for those parameters';
       RETURN row_to_json(r_row);
	END IF;

	-- return '';


    --BEGIN
        SELECT * INTO
            r_row
        FROM
            stage.websubmission_rider
        WHERE
            "UUID" = a_uuid;

        RETURN row_to_json(r_row);
    --END	
	
END  

$$;


ALTER FUNCTION nov2016.rider_info(a_uuid character varying, confirmation_parameter character varying) OWNER TO carpool_admins;

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
-- Name: urlencode(text); Type: FUNCTION; Schema: nov2016; Owner: carpool_admins
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


ALTER FUNCTION nov2016.urlencode(in_str text, OUT _result text) OWNER TO carpool_admins;

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

SET search_path = import, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: zip_code_database_commercial; Type: TABLE; Schema: import; Owner: eric
--

CREATE TABLE zip_code_database_commercial (
    zip text,
    type text,
    decommissioned text,
    primary_city text,
    acceptable_cities text,
    unacceptable_cities text,
    state text,
    county text,
    timezone text,
    area_codes text,
    world_region text,
    country text,
    latitude text,
    longitude text,
    precise_latitude text,
    precise_longitude text,
    latitude_min text,
    latitude_max text,
    longitude_min text,
    longitude_max text,
    area_land text,
    housing_count text,
    estimated_households_2005 text,
    estimated_households_2006 text,
    estimated_households_2007 text,
    estimated_households_2008 text,
    estimated_households_2009 text,
    estimated_households_2010 text,
    estimated_households_2011 text,
    estimated_households_2012 text,
    estimated_households_2013 text,
    estimated_households_2014 text,
    population_count text,
    estimated_population_2005 text,
    estimated_population_2006 text,
    estimated_population_2007 text,
    estimated_population_2008 text,
    estimated_population_2009 text,
    estimated_population_2010 text,
    estimated_population_2011 text,
    estimated_population_2012 text,
    estimated_population_2013 text,
    estimated_population_2014 text,
    white text,
    black_or_african_american text,
    american_indian_or_alaskan_native text,
    asian text,
    native_hawaiian_and_other_pacific_islander text,
    other_race text,
    two_or_more_races text,
    total_male_population text,
    total_female_population text,
    pop_under_10 text,
    pop_10_to_19 text,
    pop_20_to_29 text,
    pop_30_to_39 text,
    pop_40_to_49 text,
    pop_50_to_59 text,
    pop_60_to_69 text,
    pop_70_to_79 text,
    pop_80_plus text,
    percent_population_in_poverty text,
    median_earnings_past_year text,
    median_household_income text,
    median_gross_rent text,
    median_home_value text,
    percent_high_school_graduate text,
    percent_bachelors_degree text,
    percent_graduate_degree text
);


ALTER TABLE zip_code_database_commercial OWNER TO eric;

SET search_path = nov2016, pg_catalog;

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
-- Name: params; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE params (
    name character varying(50) NOT NULL,
    value character varying(400)
);


ALTER TABLE params OWNER TO carpool_admins;

--
-- Name: tz_dst_offset; Type: TABLE; Schema: nov2016; Owner: eric
--

CREATE TABLE tz_dst_offset (
    timezone text NOT NULL,
    observes_dst character varying(50),
    offset_summer integer,
    offset_fall integer
);


ALTER TABLE tz_dst_offset OWNER TO eric;

--
-- Name: usstate; Type: TABLE; Schema: nov2016; Owner: carpool_admins
--

CREATE TABLE usstate (
    stateabbrev character(2) NOT NULL,
    statename character varying(50)
);


ALTER TABLE usstate OWNER TO carpool_admins;

SET search_path = stage, pg_catalog;

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
    "RiderCollectionZIP" character varying(5) NOT NULL,
    "RiderDropOffZIP" character varying(5) NOT NULL,
    "AvailableRideTimesUTC" character varying(2000),
    "TotalPartySize" integer DEFAULT 1 NOT NULL,
    "TwoWayTripNeeded" boolean DEFAULT false NOT NULL,
    "RiderIsVulnerable" boolean DEFAULT false NOT NULL,
    "RiderWillNotTalkPolitics" boolean DEFAULT false NOT NULL,
    "PleaseStayInTouch" boolean DEFAULT false NOT NULL,
    "NeedWheelchair" boolean DEFAULT false NOT NULL,
    "RiderPreferredContact" character varying(50),
    "RiderAccommodationNotes" character varying(1000),
    "RiderLegalConsent" boolean DEFAULT false NOT NULL,
    "ReadyToMatch" boolean DEFAULT true NOT NULL,
    state character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    state_info text,
    "RiderWillBeSafe" boolean DEFAULT false NOT NULL,
    "AvailableRideTimesLocal" character varying(2000),
    "RiderCollectionAddress" character varying(1000),
    "RiderDestinationAddress" character varying(1000)
);


ALTER TABLE websubmission_rider OWNER TO carpool_admins;

SET search_path = nov2016, pg_catalog;

--
-- Name: vw_driver_matches; Type: VIEW; Schema: nov2016; Owner: carpool_admins
--

CREATE VIEW vw_driver_matches AS
 SELECT match.state AS "matchState",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
    websubmission_rider."UUID",
    websubmission_rider."IPAddress",
    websubmission_rider."RiderFirstName",
    websubmission_rider."RiderLastName",
    websubmission_rider."RiderEmail",
    websubmission_rider."RiderPhone",
    websubmission_rider."RiderCollectionZIP",
    websubmission_rider."RiderDropOffZIP",
    websubmission_rider."AvailableRideTimesUTC",
    websubmission_rider."TotalPartySize",
    websubmission_rider."TwoWayTripNeeded",
    websubmission_rider."RiderIsVulnerable",
    websubmission_rider."RiderWillNotTalkPolitics",
    websubmission_rider."PleaseStayInTouch",
    websubmission_rider."NeedWheelchair",
    websubmission_rider."RiderPreferredContact",
    websubmission_rider."RiderAccommodationNotes",
    websubmission_rider."RiderLegalConsent",
    websubmission_rider."ReadyToMatch",
    websubmission_rider.state,
    websubmission_rider.state_info,
    websubmission_rider."RiderWillBeSafe",
    websubmission_rider."AvailableRideTimesLocal",
    websubmission_rider."RiderCollectionAddress",
    websubmission_rider."RiderDestinationAddress"
   FROM (match
     JOIN stage.websubmission_rider ON (((websubmission_rider."UUID")::text = (match.uuid_rider)::text)));


ALTER TABLE vw_driver_matches OWNER TO carpool_admins;

SET search_path = stage, pg_catalog;

--
-- Name: websubmission_driver; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_driver (
    "UUID" character varying(50) DEFAULT public.gen_random_uuid() NOT NULL,
    "IPAddress" character varying(20),
    "DriverCollectionZIP" character varying(5) NOT NULL,
    "DriverCollectionRadius" integer DEFAULT 0 NOT NULL,
    "AvailableDriveTimesUTC" character varying(2000),
    "DriverCanLoadRiderWithWheelchair" boolean DEFAULT false NOT NULL,
    "SeatCount" integer DEFAULT 1,
    "DriverLicenseNumber" character varying(50),
    "DriverFirstName" character varying(255) NOT NULL,
    "DriverLastName" character varying(255) NOT NULL,
    "DriverEmail" character varying(255),
    "DriverPhone" character varying(20),
    "DrivingOnBehalfOfOrganization" boolean DEFAULT false NOT NULL,
    "DrivingOBOOrganizationName" character varying(255),
    "RidersCanSeeDriverDetails" boolean DEFAULT false NOT NULL,
    "DriverWillNotTalkPolitics" boolean DEFAULT false NOT NULL,
    "ReadyToMatch" boolean DEFAULT true NOT NULL,
    "PleaseStayInTouch" boolean DEFAULT false NOT NULL,
    state character varying(30) DEFAULT 'Pending'::character varying NOT NULL,
    created_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_updated_ts timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    state_info text,
    "DriverPreferredContact" character varying(50),
    "DriverWillTakeCare" boolean DEFAULT false NOT NULL,
    "AvailableDriveTimesLocal" character varying(2000)
);


ALTER TABLE websubmission_driver OWNER TO carpool_admins;

SET search_path = nov2016, pg_catalog;

--
-- Name: vw_rider_matches; Type: VIEW; Schema: nov2016; Owner: carpool_admins
--

CREATE VIEW vw_rider_matches AS
 SELECT match.state AS "matchState",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
    websubmission_driver."UUID",
    websubmission_driver."IPAddress",
    websubmission_driver."DriverCollectionZIP",
    websubmission_driver."DriverCollectionRadius",
    websubmission_driver."AvailableDriveTimesUTC",
    websubmission_driver."DriverCanLoadRiderWithWheelchair",
    websubmission_driver."SeatCount",
    websubmission_driver."DriverLicenseNumber",
    websubmission_driver."DriverFirstName",
    websubmission_driver."DriverLastName",
    websubmission_driver."DriverEmail",
    websubmission_driver."DriverPhone",
    websubmission_driver."DrivingOnBehalfOfOrganization",
    websubmission_driver."DrivingOBOOrganizationName",
    websubmission_driver."RidersCanSeeDriverDetails",
    websubmission_driver."DriverWillNotTalkPolitics",
    websubmission_driver."ReadyToMatch",
    websubmission_driver."PleaseStayInTouch",
    websubmission_driver.state,
    websubmission_driver.state_info,
    websubmission_driver."DriverPreferredContact",
    websubmission_driver."DriverWillTakeCare",
    websubmission_driver."AvailableDriveTimesLocal"
   FROM (match
     JOIN stage.websubmission_driver ON (((websubmission_driver."UUID")::text = (match.uuid_driver)::text)));


ALTER TABLE vw_rider_matches OWNER TO carpool_admins;

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
    latlong point,
    timezone character varying(50) DEFAULT ''::character varying
);


ALTER TABLE zip_codes OWNER TO carpool_admins;

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
-- Name: vw_drive_offer; Type: VIEW; Schema: stage; Owner: carpool_admins
--

CREATE VIEW vw_drive_offer AS
 SELECT websubmission_driver."UUID",
    websubmission_driver."DriverLastName",
    websubmission_driver."DriverPhone",
    websubmission_driver."DriverEmail",
    websubmission_driver.state,
    websubmission_driver."ReadyToMatch",
    websubmission_driver.created_ts,
    websubmission_driver.last_updated_ts,
    websubmission_driver."DriverCollectionZIP",
    websubmission_driver."DriverCollectionRadius",
    websubmission_driver."DriverCanLoadRiderWithWheelchair",
    websubmission_driver."SeatCount",
    websubmission_driver."DrivingOnBehalfOfOrganization",
    websubmission_driver."AvailableDriveTimesUTC",
    websubmission_driver."AvailableDriveTimesLocal"
   FROM websubmission_driver;


ALTER TABLE vw_drive_offer OWNER TO carpool_admins;

--
-- Name: vw_ride_request; Type: VIEW; Schema: stage; Owner: carpool_admins
--

CREATE VIEW vw_ride_request AS
 SELECT websubmission_rider."UUID" AS uuid,
    websubmission_rider."RiderLastName",
    websubmission_rider."RiderPhone",
    websubmission_rider."RiderEmail",
    websubmission_rider.state,
    websubmission_rider.created_ts,
    websubmission_rider.last_updated_ts,
    websubmission_rider."RiderCollectionZIP",
    websubmission_rider."RiderDropOffZIP",
    websubmission_rider."TotalPartySize",
    websubmission_rider."RiderIsVulnerable",
    websubmission_rider."NeedWheelchair",
    websubmission_rider."AvailableRideTimesUTC",
    websubmission_rider."AvailableRideTimesLocal"
   FROM websubmission_rider;


ALTER TABLE vw_ride_request OWNER TO carpool_admins;

--
-- Name: vw_unmatched_drivers; Type: TABLE; Schema: stage; Owner: carpool_admins
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
-- Name: vw_unmatched_riders; Type: TABLE; Schema: stage; Owner: carpool_admins
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
-- Name: websubmission_helper; Type: TABLE; Schema: stage; Owner: carpool_admins
--

CREATE TABLE websubmission_helper (
    "timestamp" timestamp without time zone DEFAULT now() NOT NULL,
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


--
-- Name: pk_param; Type: CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY params
    ADD CONSTRAINT pk_param PRIMARY KEY (name);


--
-- Name: tz_dst_offset_pkey; Type: CONSTRAINT; Schema: nov2016; Owner: eric
--

ALTER TABLE ONLY tz_dst_offset
    ADD CONSTRAINT tz_dst_offset_pkey PRIMARY KEY (timezone);


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
    ON SELECT TO vw_unmatched_drivers DO INSTEAD  SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM websubmission_driver driver,
    nov2016.zip_codes zip_codes
  WHERE (((driver.state)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text])) AND ((driver."DriverCollectionZIP")::text = (zip_codes.zip)::text))
  GROUP BY zip_codes.zip;


--
-- Name: _RETURN; Type: RULE; Schema: stage; Owner: carpool_admins
--

CREATE RULE "_RETURN" AS
    ON SELECT TO vw_unmatched_riders DO INSTEAD  SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM websubmission_rider rider,
    nov2016.zip_codes zip_codes
  WHERE (((rider.state)::text = ANY (ARRAY[('Pending'::character varying)::text, ('MatchProposed'::character varying)::text])) AND ((rider."RiderCollectionZIP")::text = (zip_codes.zip)::text))
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
-- Name: match_uuid_driver_fkey; Type: FK CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY match
    ADD CONSTRAINT match_uuid_driver_fkey FOREIGN KEY (uuid_driver) REFERENCES stage.websubmission_driver("UUID") ON DELETE CASCADE;


--
-- Name: match_uuid_rider_fkey; Type: FK CONSTRAINT; Schema: nov2016; Owner: carpool_admins
--

ALTER TABLE ONLY match
    ADD CONSTRAINT match_uuid_rider_fkey FOREIGN KEY (uuid_rider) REFERENCES stage.websubmission_rider("UUID") ON DELETE CASCADE;


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
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_cancel_drive_offer(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_cancel_drive_offer(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_confirm_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION driver_confirm_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: driver_confirmed_matches(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_confirmed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_exists(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_info(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_pause_match(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_pause_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: driver_proposed_matches(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION driver_proposed_matches(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: evaluate_match_single_pair(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) TO carpool_admins;
GRANT ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) TO PUBLIC;
GRANT ALL ON FUNCTION evaluate_match_single_pair(arg_uuid_driver character varying, arg_uuid_rider character varying) TO carpool_role;


--
-- Name: fct_modified_column(); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION fct_modified_column() FROM PUBLIC;
REVOKE ALL ON FUNCTION fct_modified_column() FROM carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_admins;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_role;
GRANT ALL ON FUNCTION fct_modified_column() TO carpool_web_role;


--
-- Name: get_param_value(character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION get_param_value(a_param_name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_param_value(a_param_name character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO carpool_admins;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO carpool_web;
GRANT ALL ON FUNCTION get_param_value(a_param_name character varying) TO carpool_role;


--
-- Name: perform_match(); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION perform_match() FROM PUBLIC;
REVOKE ALL ON FUNCTION perform_match() FROM carpool_admins;
GRANT ALL ON FUNCTION perform_match() TO carpool_admins;
GRANT ALL ON FUNCTION perform_match() TO carpool_role;
GRANT ALL ON FUNCTION perform_match() TO PUBLIC;


--
-- Name: rider_cancel_confirmed_match(character varying, character varying, smallint, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION rider_cancel_confirmed_match(a_uuid_driver character varying, a_uuid_rider character varying, a_score smallint, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: rider_cancel_ride_request(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;
GRANT ALL ON FUNCTION rider_cancel_ride_request(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;


--
-- Name: rider_confirmed_match(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_confirmed_match(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_exists(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_exists(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


--
-- Name: rider_info(character varying, character varying); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) FROM carpool_admins;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_admins;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO PUBLIC;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_web;
GRANT ALL ON FUNCTION rider_info(a_uuid character varying, confirmation_parameter character varying) TO carpool_role;


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
-- Name: urlencode(text); Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION urlencode(in_str text, OUT _result text) FROM PUBLIC;
REVOKE ALL ON FUNCTION urlencode(in_str text, OUT _result text) FROM carpool_admins;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO carpool_admins;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO PUBLIC;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO carpool_role;
GRANT ALL ON FUNCTION urlencode(in_str text, OUT _result text) TO carpool_web_role;


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
GRANT SELECT,USAGE ON SEQUENCE outgoing_email_id_seq TO carpool_role;


--
-- Name: outgoing_sms; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE outgoing_sms FROM PUBLIC;
REVOKE ALL ON TABLE outgoing_sms FROM carpool_admins;
GRANT ALL ON TABLE outgoing_sms TO carpool_admins;
GRANT ALL ON TABLE outgoing_sms TO carpool_role;
GRANT INSERT ON TABLE outgoing_sms TO carpool_web;


--
-- Name: outgoing_sms_id_seq; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON SEQUENCE outgoing_sms_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE outgoing_sms_id_seq FROM carpool_admins;
GRANT ALL ON SEQUENCE outgoing_sms_id_seq TO carpool_admins;
GRANT SELECT,USAGE ON SEQUENCE outgoing_sms_id_seq TO carpool_web;
GRANT SELECT,USAGE ON SEQUENCE outgoing_sms_id_seq TO carpool_role;


--
-- Name: params; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE params FROM PUBLIC;
REVOKE ALL ON TABLE params FROM carpool_admins;
GRANT ALL ON TABLE params TO carpool_admins;
GRANT SELECT ON TABLE params TO carpool_role;
GRANT SELECT ON TABLE params TO carpool_web_role;


SET search_path = stage, pg_catalog;

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


SET search_path = nov2016, pg_catalog;

--
-- Name: vw_driver_matches; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_driver_matches FROM PUBLIC;
REVOKE ALL ON TABLE vw_driver_matches FROM carpool_admins;
GRANT ALL ON TABLE vw_driver_matches TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE vw_driver_matches TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_driver_matches TO carpool_role;
GRANT SELECT ON TABLE vw_driver_matches TO carpool_web;


SET search_path = stage, pg_catalog;

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


SET search_path = nov2016, pg_catalog;

--
-- Name: vw_rider_matches; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_rider_matches FROM PUBLIC;
REVOKE ALL ON TABLE vw_rider_matches FROM carpool_admins;
GRANT ALL ON TABLE vw_rider_matches TO carpool_admins;
GRANT SELECT,INSERT,UPDATE ON TABLE vw_rider_matches TO carpool_web_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_rider_matches TO carpool_role;
GRANT SELECT ON TABLE vw_rider_matches TO carpool_web;


--
-- Name: zip_codes; Type: ACL; Schema: nov2016; Owner: carpool_admins
--

REVOKE ALL ON TABLE zip_codes FROM PUBLIC;
REVOKE ALL ON TABLE zip_codes FROM carpool_admins;
GRANT ALL ON TABLE zip_codes TO carpool_admins;
GRANT ALL ON TABLE zip_codes TO carpool_role;


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
-- Name: vw_drive_offer; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_drive_offer FROM PUBLIC;
REVOKE ALL ON TABLE vw_drive_offer FROM carpool_admins;
GRANT ALL ON TABLE vw_drive_offer TO carpool_admins;
GRANT SELECT ON TABLE vw_drive_offer TO carpool_role;


--
-- Name: vw_ride_request; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_ride_request FROM PUBLIC;
REVOKE ALL ON TABLE vw_ride_request FROM carpool_admins;
GRANT ALL ON TABLE vw_ride_request TO carpool_admins;
GRANT SELECT ON TABLE vw_ride_request TO carpool_role;


--
-- Name: vw_unmatched_drivers; Type: ACL; Schema: stage; Owner: carpool_admins
--

REVOKE ALL ON TABLE vw_unmatched_drivers FROM PUBLIC;
REVOKE ALL ON TABLE vw_unmatched_drivers FROM carpool_admins;
GRANT ALL ON TABLE vw_unmatched_drivers TO carpool_admins;
GRANT SELECT ON TABLE vw_unmatched_drivers TO carpool_web_role;
GRANT SELECT ON TABLE vw_unmatched_drivers TO carpool_role;


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

