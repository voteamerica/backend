----------------------------------------------------------
-- Common function to return HTML header
----------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notifications_html_header() 
RETURNS character varying AS
$BODY$
BEGIN

	RETURN '<!doctype html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'
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
END
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
  
----------------------------------------------------------
-- Common function to return HTML footer
----------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notifications_html_footer() 
RETURNS character varying AS
$BODY$
BEGIN
	RETURN '</html>'; 
END
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
  
----------------------------------------------------------
-- Email/SMS notifications to driver after new submission
----------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_new_driver(
	uuid carpoolvote.driver."UUID"%TYPE,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
 v_driver_record carpoolvote.driver%ROWTYPE;
 v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
 v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
 v_html_header carpoolvote.outgoing_email.body%TYPE;
 v_html_body   carpoolvote.outgoing_email.body%TYPE;
 v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN        
	out_error_code := 0;
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * FROM carpoolvote.driver WHERE "UUID" = uuid INTO v_driver_record;
	
        IF v_driver_record."DriverEmail" IS NOT NULL                                                                                   
        THEN                                                                                                               

            v_subject := 'Driver Offer received!   --- [' || v_driver_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" || ', <p>' 
			|| '<p>We have received your offer to give someone a ride to claim their vote - THANK YOU!</p>'
			|| '<p>Your Driver Offer reference is: ' || v_driver_record."UUID" || '<br/>'
			|| 'Please keep this reference in case you need to manage your offer.</p>'
			|| 'We will get in touch as soon as there are riders who match your criteria. Please check that the below details are correct:<br/>'
			|| '<table>'
			|| '<tr><td class="evenRow">Pick-up ZIP</td><td class="evenRow">' || v_driver_record."DriverCollectionZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Radius</td><td class="oddRow">' || v_driver_record."DriverCollectionRadius" || ' miles</td></tr>'
			|| '<tr><td class="evenRow">Drive Times</td><td class="evenRow">' || replace(replace(replace(replace(replace(v_driver_record."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Seats</td><td class="oddRow">' || v_driver_record."SeatCount" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessible</td><td class="evenRow">' || CASE WHEN v_driver_record."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || v_driver_record."DriverPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || v_driver_record."DriverEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=driver&uuid=' || v_driver_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName") ||  '">Cancel this offer</a></p>'  -- yes, this is correct, the API uses DriverPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;


            INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)                                             
            VALUES (v_driver_record."DriverEmail", v_subject, v_body);                                                                 
        END IF;                                                                                                            

		IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
        THEN                                                                                                               
            v_body :=  'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Driver offer received! Ref: ' || v_driver_record."UUID" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up ZIP : ' || v_driver_record."DriverCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Radius : ' || v_driver_record."DriverCollectionRadius" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Drive Times  : ' || replace(replace(replace(replace(replace(v_driver_record."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Seats : ' || v_driver_record."SeatCount" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Wheelchair accessible : ' || CASE WHEN v_driver_record."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Phone Number : ' || v_driver_record."DriverPhone" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Self-Service portal : http://carpoolvote.com/self-service/?type=driver&uuid=' || v_driver_record."UUID" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Cancel : https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName");
					
            INSERT INTO carpoolvote.outgoing_sms (recipient, body)                                             
            VALUES (v_driver_record."DriverPhone", v_body);                                                                 
        END IF;                                                                                                            
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception (' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
  
ALTER FUNCTION carpoolvote.notify_new_driver(character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_new_driver(character varying, OUT integer, out text) TO carpool_web;

----------------------------------------------------------
-- Email/SMS notifications to rider after new submission
----------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_new_rider(
	uuid carpoolvote.rider."UUID"%TYPE,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
 v_rider_record carpoolvote.rider%ROWTYPE;
 v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
 v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
 v_html_header carpoolvote.outgoing_email.body%TYPE;
 v_html_body   carpoolvote.outgoing_email.body%TYPE;
 v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := 0;
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * FROM carpoolvote.rider WHERE "UUID" = uuid INTO v_rider_record;
                                                                                                                
        IF v_rider_record."RiderEmail" IS NOT NULL                                                                                    
        THEN                                                                                                               

			v_subject := 'Ride Request received!   --- [' || v_rider_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_rider_record."RiderFirstName" ||  ' ' || v_rider_record."RiderLastName" || ', <p>' 
			|| '<p>We’ve received your request for a ride. CONGRATULATIONS on taking this step to claim your vote!</p>'
			|| '<p>Your Ride Request reference is: ' || v_rider_record."UUID" || '<br/>'
			|| 'Please keep this reference in case you need to manage your ride request.</p>'
			|| 'We will get in touch as soon as a driver has offered to give you a ride. Please check that the below details are correct:<br/>'
			|| '<table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || replace(replace(replace(replace(replace(v_rider_record."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up Address</td><td class="oddRow">' || COALESCE(v_rider_record."RiderCollectionAddress", ' ') || '</td></tr>'
			|| '<tr><td class="evenRow">Pick-up ZIP</td><td class="evenRow">' || v_rider_record."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Destination Address</td><td class="oddRow">' || COALESCE(v_rider_record."RiderDestinationAddress", ' ') || '</td></tr>'
			|| '<tr><td class="evenRow">Destination ZIP</td><td class="evenRow">' || v_rider_record."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || v_rider_record."RiderPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || v_rider_record."RiderEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=rider&uuid=' || v_rider_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName") ||  '">Cancel this request</a></p>' -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;
            INSERT INTO carpoolvote.outgoing_email (recipient, subject, body)                                             
            VALUES (v_rider_record."RiderEmail", v_subject, v_body);                                                                  
        END IF;

		IF v_rider_record."RiderPhone" IS NOT NULL AND (position('SMS' in v_rider_record."RiderPreferredContact") > 0)                                                                               
        THEN                                                                                                               
            v_body := 'From CarpoolVote.com' || ' ' || carpoolvote.urlencode(chr(10)) 
					|| ' Ride Request received! Ref: ' || v_rider_record."UUID" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(v_rider_record."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Pick-up : ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Destination : ' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Wheelchair accessibility needed : ' ||  CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Two-way trip needed : ' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Notes : ' ||  v_rider_record."RiderAccommodationNotes" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Phone Number : ' ||  v_rider_record."RiderPhone" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Self-Service portal : http://carpoolvote.com/self-service/?type=rider&uuid=' || v_rider_record."UUID" || ' ' || carpoolvote.urlencode(chr(10))
					|| ' Cancel : https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName");
				
            INSERT INTO carpoolvote.outgoing_sms (recipient, body)                                             
            VALUES (v_rider_record."RiderPhone", v_body);                                                                 
        END IF;                    
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception (' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.notify_new_rider(character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_new_rider(character varying, OUT integer, out text) TO carpool_web;

