----------------------------------------------------------
-- determines the status of the outgoing sms when it's inserted
-- default is 'Pending'
-- But if parameter outgoing_sms_whitelist.enabled is true,
-- and the phone number is not found in the sms_whitelist table
-- the record is inserted with status 'Blocked'
----------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.outgoing_sms_insert_status(
	in_phone_number carpoolvote.outgoing_sms.recipient%TYPE ) 
RETURNS character varying AS
$BODY$
BEGIN



IF EXISTS (
	SELECT 1 FROM carpoolvote.sms_whitelist
	WHERE regexp_replace( regexp_replace(COALESCE(phone_number, ''),'(\D)', '', 'g'), '^1', '', 'g')  -- strips everything that is not numeric and the first one 
			= regexp_replace( regexp_replace(COALESCE(in_phone_number, ''),'(\D)', '', 'g'), '^1', '', 'g') -- strips everything that is not numeric and the first one 
	UNION
	SELECT 1 FROM carpoolvote.params
	WHERE name = 'outgoing_sms_whitelist.enabled' and value = 'false'   -- white list must be explicitly turned off
) THEN
	RETURN 'Pending';
ELSE
	RETURN 'Blocked';
END IF;

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.outgoing_sms_insert_status(character varying) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.outgoing_sms_insert_status(character varying) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.outgoing_sms_insert_status(character varying) TO carpool_role;


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
ALTER FUNCTION carpoolvote.notifications_html_header() OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notifications_html_header() TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notifications_html_header() TO carpool_role;
  
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
ALTER FUNCTION carpoolvote.notifications_html_footer() OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notifications_html_footer() TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notifications_html_footer() TO carpool_role;

  
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
			|| '<tr><td class="evenRow">Drive Times</td><td class="evenRow">' || carpoolvote.convert_datetime_to_local_format(v_driver_record."AvailableDriveTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Seats</td><td class="oddRow">' || v_driver_record."SeatCount" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessible</td><td class="evenRow">' || CASE WHEN v_driver_record."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || v_driver_record."DriverPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || v_driver_record."DriverEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName") ||  '">Cancel this offer</a></p>'  -- yes, this is correct, the API uses DriverPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;


            INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)                                             
            VALUES (v_driver_record."DriverEmail", v_driver_record."UUID", v_subject, v_body);                                                                 
        END IF;                                                                                                            

		IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
        THEN                                                                                                               
            v_body :=  'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Driver offer received! Ref: ' || v_driver_record."UUID" || ' ' || chr(10)
					|| ' Pick-up ZIP : ' || v_driver_record."DriverCollectionZIP" || ' ' || chr(10)
					|| ' Radius : ' || v_driver_record."DriverCollectionRadius" || ' ' || chr(10)
					|| ' Drive Times  : ' || carpoolvote.convert_datetime_to_local_format(v_driver_record."AvailableDriveTimesLocal") || ' ' || chr(10)
					|| ' Seats : ' || v_driver_record."SeatCount" || ' ' || chr(10)
					|| ' Wheelchair accessible : ' || CASE WHEN v_driver_record."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || ' ' || chr(10)
					|| ' Phone Number : ' || v_driver_record."DriverPhone" || ' ' || chr(10)
					|| ' Self-Service portal : ' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || ' ' || chr(10);
					-- ISSUE #124|| ' Cancel : https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName");
					
            INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)                                             
            VALUES (v_driver_record."DriverPhone", v_driver_record."UUID", v_body, carpoolvote.outgoing_sms_insert_status(v_driver_record."DriverPhone"));                                                                 
        END IF;                                                                                                            
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_new_driver(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
  
ALTER FUNCTION carpoolvote.notify_new_driver(character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_new_driver(character varying, OUT integer, out text) TO carpool_web_role;

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
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up Address</td><td class="oddRow">' 
			|| COALESCE(v_rider_record."RiderCollectionStreetNumber", '') || ' ' || COALESCE(v_rider_record."RiderCollectionAddress", ' ') || '</td></tr>'
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
			|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=rider&uuid=' || v_rider_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName") ||  '">Cancel this request</a></p>' -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;
            INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)                                             
            VALUES (v_rider_record."RiderEmail", v_rider_record."UUID", v_subject, v_body);                                                                  
        END IF;

		IF v_rider_record."RiderPhone" IS NOT NULL AND (position('SMS' in v_rider_record."RiderPreferredContact") > 0)                                                                               
        THEN                                                                                                               
            v_body := 'From CarpoolVote.com' || ' ' || chr(10) 
					|| ' Ride Request received! Ref: ' || v_rider_record."UUID" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || ' ' || chr(10)
					|| ' Pick-up : ' 
					|| COALESCE(v_rider_record."RiderCollectionStreetNumber", '') || ' ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') 
					|| v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Destination : ' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Wheelchair accessibility needed : ' ||  CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || ' ' || chr(10)
					|| ' Two-way trip needed : ' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END || ' ' || chr(10)
					|| ' Notes : ' ||  v_rider_record."RiderAccommodationNotes" || ' ' || chr(10)
					|| ' Phone Number : ' ||  v_rider_record."RiderPhone" || ' ' || chr(10)
					|| ' Self-Service portal : ' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=rider&uuid=' || v_rider_record."UUID" || ' ' || chr(10)
					|| ' User support : 540-656-9388 ' || chr(10)
					|| ' Cancel : https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName");
				
            INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)                                             
            VALUES (v_rider_record."RiderPhone",v_rider_record."UUID",  v_body, carpoolvote.outgoing_sms_insert_status(v_rider_record."RiderPhone"));                                                                 
        END IF;                    
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_new_rider(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.notify_new_rider(character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_new_rider(character varying, OUT integer, out text) TO carpool_web_role;


----------------------------------------------------------
-- Email/SMS notifications to driver for new available matches
----------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_driver_new_available_matches(
	uuid character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
	v_record record;
	v_loop_cnt integer;
	v_row_style text;
 
BEGIN                                                                                                                      
	out_error_code := 0;
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * FROM carpoolvote.driver WHERE "UUID" = uuid INTO v_driver_record;
			v_subject := 'Proposed rider match update!   --- [' || v_driver_record."UUID" || ']';
			v_html_body := '<body>'
				|| '<p>Dear ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" || ', <p>' 
				|| '<p>Great news - we found riders who match your criteria!</p>'
				|| '<p><table>'
				|| '<tr>' 
				|| '<td class="oddRow">Action</td>'
				|| '<td class="oddRow">Status</td>'
				|| '<td class="oddRow">Pick-up location</td>'
				|| '<td class="oddRow">Destination</td>'
				|| '<td class="oddRow">Preferred Ride Times</td>'
				|| '<td class="oddRow">Party Size</td>'
				|| '<td class="oddRow">Wheelchair accessibility needed</td>'
				|| '<td class="oddRow">Two-way trip needed</td>'
				|| '<td class="oddRow">Notes</td>'
				--|| '<td class="oddRow">Name</td>'
				--|| '<td class="oddRow">Email (*=preferred)</td>'
				--|| '<td class="oddRow">Phone Number (*)=preferred</td>'
				|| '</tr>';

			--RAISE NOTICE 'BODY 1 : %', v_html_body;
			
            v_loop_cnt := 0;
			FOR v_record IN SELECT * FROM carpoolvote.match m 
									WHERE m.uuid_driver = v_driver_record."UUID" AND status <> 'ExtendedMatch' order by score asc
			LOOP
                v_row_style := CASE WHEN v_loop_cnt % 2 =1 THEN 'oddRow' else 'evenRow' END;
					
				SELECT * INTO v_rider_record FROM carpoolvote.rider r
												WHERE r."UUID" = v_record.uuid_rider;

				v_html_body := v_html_body 
                    || '<tr>' 
                    || '<td class="' || v_row_style || '">' ||
                        CASE
						WHEN v_record.status='MatchProposed' THEN '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/accept-driver-match' 
                            || '?UUID_driver=' || v_driver_record."UUID"
                            || '&UUID_rider=' || v_record.uuid_rider
                            || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName" )   -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
                            || '">Accept</a>'
						WHEN v_record.status='MatchConfirmed' THEN '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-driver-match' 
                            || '?UUID_driver=' || v_driver_record."UUID"
                            || '&UUID_rider=' || v_record.uuid_rider
                            || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName" )   -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
                            || '">Cancel</a>'
                        ELSE '' END || '</td>'
					|| '<td class="' || v_row_style || '">' ||
					CASE 
					WHEN v_record.status='MatchProposed' THEN 'Proposed'
					WHEN v_record.status='ExtendedMatch' THEN 'Extra'
					WHEN v_record.status='MatchConfirmed' THEN 'Confirmed'
					ELSE v_record.status END || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td>'
                    || '<td class="' || v_row_style || '">' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal")  || '</td>'
                    || '<td class="' || v_row_style || '">' || v_rider_record."TotalPartySize" || '</td>'
                    || '<td class="' || v_row_style || '">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td>'
                    || '<td class="' || v_row_style || '">' || CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END || '</td>'
                    || '<td class="' || v_row_style || '">' || COALESCE (v_rider_record."RiderAccommodationNotes", ' ') || '</td>'
                    --|| '<td class="' || v_row_style || '">' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName"  || '</td>'
                    --|| '<td class="' || v_row_style || '">' || COALESCE(v_rider_record."RiderEmail", ' ') || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || '</td>'
                    --|| '<td class="' || v_row_style || '">' || COALESCE(v_rider_record."RiderPhone", ' ') || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%Phone%', false) THEN '(*)' Else ' ' END || '</td>'
                    || '</tr>';
                
				--RAISE NOTICE 'BODY 2 : % % %', v_html_body, v_row_style, v_rider_record."UUID";
				
				
				v_loop_cnt := v_loop_cnt + 1;
			END LOOP;
			
			
			--RAISE NOTICE 'BODY 3 : %', v_html_body;
			
            v_html_body := v_html_body || '</table></p>'
                || '<p>If you do not wish to accept the proposed rides, you do not need to do anything. A match is only confirmed once you have accepted it.</p>'
				|| '<p>If you do not with to receive future notifications about new proposed matches for this Driver Offer, please <a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/pause-match-driver?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName") ||  '">click here</a></p>'            
                || '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName") ||  '">Cancel your Drive Offer</a></p>'
                || '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || '">self-service portal</a>.</p>'
				|| '<p>Warm wishes</p>'
                || '<p>The CarpoolVote.com team.</p>'
                || '</body>';

            v_body := v_html_header || v_html_body || v_html_footer;
			--RAISE NOTICE 	'%', v_driver_record."UUID";
			--RAISE NOTICE '%', v_body;
			--RAISE NOTICE '%', v_html_header;
			--RAISE NOTICE '%', v_html_body;
			--RAISE NOTICE '%', v_html_footer;
			
			IF v_driver_record."DriverEmail" IS NOT NULL
			THEN
				INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
				VALUES (v_driver_record."DriverEmail", v_driver_record."UUID", v_subject, v_body);
				
			END IF;
				
			IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
			THEN

				v_loop_cnt := 0;
				v_body := 'From CarpoolVote.com' || ' ' || chr(10) 
						|| ' New matches are available.' || ' ' || chr(10)
				        || ' Please visit the self-service page for details ' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || ' ' || chr(10);			
			
				FOR v_record IN SELECT * FROM carpoolvote.match m 
									WHERE m.uuid_driver = v_driver_record."UUID" AND status <> 'ExtendedMatch' order by score asc
				LOOP
				
					SELECT * INTO v_rider_record FROM carpoolvote.rider r
						WHERE r."UUID" = v_record.uuid_rider;

					v_body := v_body
					|| '__________' || chr(10)
	                || 'From ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || chr(10)
                    || 'To ' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || chr(10)
                    || 'When ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal")  || chr(10)
                    || 'Party of '|| v_rider_record."TotalPartySize" || chr(10);
				END LOOP;
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_driver_record."DriverPhone", v_driver_record."UUID", v_body, carpoolvote.outgoing_sms_insert_status(v_driver_record."DriverPhone"));
			
			END IF;
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_driver_new_available_matches(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_driver_new_available_matches(character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_new_available_matches(character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_new_available_matches(character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_new_available_matches(character varying, OUT integer, out text) TO carpool_admins;



---------------------------------------------------------------------
-- USER STORY 003
-- Email/SMS notifications to driver for ride cancellation by rider
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_driver_ride_cancelled_by_rider(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
	
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
			SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
			SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;
		
			IF v_driver_record."DriverEmail" IS NOT NULL
			THEN
				
				-- Cancellation notice to driver
				v_subject := 'Confirmed Ride Cancellation Notice   --- [' || v_driver_record."UUID" || ']';
				v_html_body := '<body>'
				|| '<p>Dear ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" || ', <p>' 
				|| '<p>' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" 
				|| ' no longer needs a ride. </p>'
				|| '<p>These were the ride details: </p>'
				|| '<p><table>'
				|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
					carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">'  || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') ||  v_rider_record."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>Hopefully you can help another rider in your area.</p>'
				|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
				VALUES (v_driver_record."DriverEmail", v_driver_record."UUID", v_subject, v_body);
			END IF;
			
			IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
			THEN
			
				v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Confirmed Ride was canceled by rider. No further action needed.' || ' ' || chr(10)
					|| ' Rider : ' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" || ' ' || chr(10)
					|| ' Pick-up location : '  ||  COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal");
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_driver_record."DriverPhone", v_driver_record."UUID", v_body, carpoolvote.outgoing_sms_insert_status(v_driver_record."DriverPhone"));
			END IF;

		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_driver_ride_cancelled_by_rider(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_driver_ride_cancelled_by_rider(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_ride_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_ride_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_ride_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_admins;

---------------------------------------------------------------------
-- USER STORY 003
-- Email/SMS notifications to rider for ride cancellation by rider
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_rider_ride_cancelled_by_rider(
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;
		
		IF v_rider_record."RiderEmail" IS NOT NULL
		THEN
			v_subject := 'Ride Request Cancellation Notice   --- [' || v_rider_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" || ', </p>'
			|| '<p>We have processed your request to cancel a ride request. If a ride had already been confirmed, the driver has been notified.</p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;
			
			INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
			VALUES (v_rider_record."RiderEmail", uuid_rider, v_subject, v_body);
		END IF;
			
		IF v_rider_record."RiderPhone" IS NOT NULL AND (position('SMS' in v_rider_record."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Ride Request ' || v_rider_record."UUID"  || ' was canceled. No further action needed.' || ' ' || chr(10)
					|| ' Pick-up location : ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || ' ' || chr(10)
					|| ' User support : 540-656-9388 ';
		
			INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
			VALUES (v_rider_record."RiderPhone", uuid_rider, v_body, carpoolvote.outgoing_sms_insert_status(v_rider_record."RiderPhone"));
		END IF;
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_rider_ride_cancelled_by_rider(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_rider_ride_cancelled_by_rider(character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_ride_cancelled_by_rider(character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_ride_cancelled_by_rider(character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_ride_cancelled_by_rider(character varying, OUT integer, out text) TO carpool_admins;


---------------------------------------------------------------------
-- USER STORY 004
-- Email/SMS notifications to driver for confirmed match cancellation by rider
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_rider(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;
		
		IF v_driver_record."DriverEmail" IS NOT NULL
		THEN
			-- Cancellation notice to driver
				v_subject := 'Confirmed Ride Cancellation Notice   --- [' || v_driver_record."UUID" || ']';
				v_html_body := '<body>'
				|| '<p>Dear ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" || ', <p>' 
				|| '<p>' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" 
				|| ' no longer needs a ride.</p>'
				|| '<p>These were the ride details: </p>'
				|| '<p><table>'
				|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
					carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>Hopefully you can help another rider in your area.</p>'
				|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
				VALUES (v_driver_record."DriverEmail", v_driver_record."UUID", v_subject, v_body);
		END IF;
		
		IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Confirmed Ride was canceled by rider. No further action needed.' || ' ' || chr(10)
					|| ' Rider : ' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" || ' ' || chr(10)
					|| ' Pick-up location : ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal");
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_driver_record."DriverPhone", v_driver_record."UUID", v_body, carpoolvote.outgoing_sms_insert_status(v_driver_record."DriverPhone"));
		END IF;

		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_driver_confirmed_match_cancelled_by_rider(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_admins;



---------------------------------------------------------------------
-- USER STORY 004
-- Email/SMS notifications to rider for confirmed match cancellation by rider
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_rider(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;
		
		IF v_rider_record."RiderEmail" IS NOT NULL
		THEN
			-- Cancellation notice to rider
			v_subject := 'Confirmed Ride Cancellation Notice   --- [' || v_rider_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" || ', </p>'
			|| '<p>We have processed your request to cancel a confirmed ride with ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" || '</p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>We will try to find another suitable driver.</p>'
			|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=rider&uuid=' || v_rider_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
			VALUES (v_rider_record."RiderEmail", v_rider_record."UUID", v_subject, v_body);
			
		END IF;
			
		IF v_rider_record."RiderPhone" IS NOT NULL AND (position('SMS' in v_rider_record."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Confirmed Ride was canceled. No further action needed.' || ' ' || chr(10)
					|| ' Pick-up location : ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' 
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || ' ' || chr(10)
					|| ' User support : 540-656-9388 ';
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_rider_record."RiderPhone", v_rider_record."UUID", v_body, carpoolvote.outgoing_sms_insert_status(v_rider_record."RiderPhone"));
		END IF;
				
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_rider_confirmed_match_cancelled_by_rider (' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_rider(character varying, character varying, OUT integer, out text) TO carpool_admins;


---------------------------------------------------------------------
-- USER STORY 013
-- Email/SMS notifications to driver for drive cancellation by driver
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_driver_drive_cancelled_by_driver(
	uuid_driver character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		
		IF v_driver_record."DriverEmail" IS NOT NULL
		THEN
			
			v_subject := 'Drive Offer is canceled   --- [' || v_driver_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" || ', <p>' 
			|| '<p>We have received your request to cancel your drive offer.</p>'
			|| 'These were the details of the offer:<br/>'
			|| '<table>'
			|| '<tr><td class="evenRow">Pick-up ZIP</td><td class="evenRow">' || v_driver_record."DriverCollectionZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Radius</td><td class="oddRow">' || v_driver_record."DriverCollectionRadius" || ' miles</td></tr>'
			|| '<tr><td class="evenRow">Drive Times</td><td class="evenRow">' || carpoolvote.convert_datetime_to_local_format(v_driver_record."AvailableDriveTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Seats</td><td class="oddRow">' || v_driver_record."SeatCount" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessible</td><td class="evenRow">' || CASE WHEN v_driver_record."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || v_driver_record."DriverPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || v_driver_record."DriverEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is necessary.</p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;


            INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)                                             
            VALUES (v_driver_record."DriverEmail", uuid_driver, v_subject, v_body);                                                                 
			
		END IF;
	
		IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Drive Offer ' || v_driver_record."UUID" ||  ' was canceled. No further action needed.' || ' ' || chr(10)
					|| ' Pick-up ZIP : ' || v_driver_record."DriverCollectionZIP" || ' ' || chr(10)
					|| ' Radius : ' || v_driver_record."DriverCollectionRadius" || ' ' || chr(10)
					|| ' Drive Times : ' || carpoolvote.convert_datetime_to_local_format(v_driver_record."AvailableDriveTimesLocal"); 
			
			INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
			VALUES (v_driver_record."DriverPhone", uuid_driver, v_body, carpoolvote.outgoing_sms_insert_status(v_driver_record."DriverPhone"));
		END IF;
		

		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_driver_drive_cancelled_by_driver(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_driver_drive_cancelled_by_driver(character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_drive_cancelled_by_driver(character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_drive_cancelled_by_driver(character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_drive_cancelled_by_driver(character varying, OUT integer, out text) TO carpool_admins;

---------------------------------------------------------------------
-- USER STORY 013
-- Email/SMS notifications to rider for drive cancellation by driver
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_rider_drive_cancelled_by_driver(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                               
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();

		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;
		
		IF v_rider_record."RiderEmail" IS NOT NULL
		THEN
				-- Cancellation notice to rider
				v_subject := 'Confirmed Ride Cancellation Notice   --- [' || v_rider_record."UUID" || ']';
				v_html_body := '<body>'
				|| '<p>Dear ' || v_rider_record."RiderFirstName" ||  ' ' || v_rider_record."RiderLastName" || ', <p>' 
				|| '<p>Your driver ' || v_driver_record."DriverFirstName" || ' ' || v_driver_record."DriverLastName" 
				|| ' has canceled this ride. </p>'
				|| '<p>These were the ride details: </p>'
				|| '<p><table>'
				|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
					carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
				|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
				|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td></tr>'
				|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
				|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
				|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
				|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
				|| '</table>'
				|| '</p>'
				|| '<p>Concerning this ride, no further action is needed from you.</p>'
				|| '<p>We will try to find another suitable driver.</p>'
				|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=rider&uuid=' || v_rider_record."UUID" || '">Self-Service Portal</a></p>'
				|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName") ||  '">cancel this Ride Request</a></p>'
				|| '<p>Warm wishes</p>'
				|| '<p>The CarpoolVote.com team.</p>'
				|| '</body>';

				v_body := v_html_header || v_html_body || v_html_footer;

				INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
				VALUES (v_rider_record."RiderEmail", uuid_rider, v_subject, v_body);

			
			END IF;
			
			IF v_rider_record."RiderPhone" IS NOT NULL AND (position('SMS' in v_rider_record."RiderPreferredContact") > 0)
			THEN
		
				v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Confirmed Ride was canceled by driver. No further action needed.' || ' ' || chr(10)
					|| ' Driver : ' || v_driver_record."DriverFirstName" || ' ' || v_driver_record."DriverLastName" || ' ' || chr(10)
					|| ' Pick-up location : ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || ' ' || chr(10)
					|| ' User support : 540-656-9388 ';
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_rider_record."RiderPhone", uuid_rider, v_body, carpoolvote.outgoing_sms_insert_status(v_rider_record."RiderPhone"));
			END IF;
			
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_rider_drive_cancelled_by_driver(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_rider_drive_cancelled_by_driver(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_drive_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_drive_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_drive_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_admins;



---------------------------------------------------------------------
-- USER STORY 014
-- Email/SMS notifications to driver for confirmed match cancellation by driver
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_driver(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                                                                                                                    
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();
		
		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;

		IF v_driver_record."DriverEmail" IS NOT NULL
		THEN

			v_subject := 'Confirmed Ride Cancellation Notice   --- [' || v_driver_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" ||  ', </p>'
			|| '<p>We have processed your request to cancel a confirmed ride with ' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" || '</p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>No further action is needed from you.</p>'
			|| '<p>We hope you can still are still able to help another rider.</p>'
			|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If are no longer able to offer a ride, please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName") ||  '">cancel this Drive Offer</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
			
			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
			VALUES (v_driver_record."DriverEmail", uuid_driver, v_subject, v_body);
		
		END IF;
		
		IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Confirmed Ride was canceled. No further action needed.' || ' ' || chr(10)
					|| ' Rider : ' ||  v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName"  || ' ' || chr(10)
					|| ' Pick-up location : ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal");
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_driver_record."DriverPhone", uuid_driver, v_body, carpoolvote.outgoing_sms_insert_status(v_driver_record."DriverPhone"));
		END IF;		

		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_driver_confirmed_match_cancelled_by_driver(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_admins;

---------------------------------------------------------------------
-- USER STORY 014
-- Email/SMS notifications to rider for confirmed match cancellation by driver
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_driver(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                               
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();

		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;

		IF v_rider_record."RiderEmail" IS NOT NULL
		THEN
			-- Cancellation notice to rider
			v_subject := 'Confirmed Ride Cancellation Notice   --- [' || v_rider_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_rider_record."RiderFirstName" ||  ' ' || v_rider_record."RiderLastName" || ', <p>' 
			|| '<p>Your driver ' || v_driver_record."DriverFirstName" || ' ' || v_driver_record."DriverLastName" 
			|| ' has canceled this ride. </p>'
			|| '<p>These were the ride details: </p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>Concerning this ride, no further action is needed from you.</p>'
			|| '<p>We will try to find another suitable driver.</p>'
			|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=rider&uuid=' || v_rider_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
			VALUES (v_rider_record."RiderEmail", v_rider_record."UUID", v_subject, v_body);

		END IF;
		
		IF v_rider_record."RiderPhone" IS NOT NULL AND (position('SMS' in v_rider_record."RiderPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Confirmed Ride was canceled by driver. No further action needed.' || ' ' || chr(10)
					|| ' Driver : ' ||  v_driver_record."DriverFirstName" || ' ' || v_driver_record."DriverLastName"  || ' ' || chr(10)
					|| ' Pick-up location : ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || ' ' || chr(10)
					|| ' User support : 540-656-9388 ';
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_rider_record."RiderPhone", uuid_rider, v_body, carpoolvote.outgoing_sms_insert_status(v_rider_record."RiderPhone"));
		END IF;
				
		
		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_rider_confirmed_match_cancelled_by_driver(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_confirmed_match_cancelled_by_driver(character varying, character varying, OUT integer, out text) TO carpool_admins;


---------------------------------------------------------------------
-- USER STORY 015
-- Email/SMS notifications to driver for confirmed match by driver
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_driver_match_confirmed_by_driver(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                               
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();

		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;

		IF v_driver_record."DriverEmail" IS NOT NULL
		THEN
			-- confirmation notice to driver
			v_subject := 'Contact details for accepted ride   --- [' || v_driver_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_driver_record."DriverFirstName" ||  ' ' || v_driver_record."DriverLastName" || ', <p>' 
			|| '<p>You have accepted a proposed match for a rider - THANK YOU!</p>'
			|| '<p>' || v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName" 
			|| ' is now waiting for you to get in touch to arrange the details of the ride.</p>'
			|| '<p>Please contact the rider as soon as possible via <br/>'
			|| CASE WHEN v_rider_record."RiderEmail" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || 'Email: ' || v_rider_record."RiderEmail"  ELSE ' ' END || '<br/>'
			|| CASE WHEN v_rider_record."RiderPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%Phone%',false) THEN '(*)' else ' ' END || 'Phone: ' || v_rider_record."RiderPhone"  ELSE ' ' END || '<br/>'
			|| CASE WHEN v_rider_record."RiderPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%SMS%',false) THEN '(*)' else ' ' END || 'SMS/Text: ' || v_rider_record."RiderPhone"  ELSE ' ' END || '<br/>'
			|| '(*) = Preferred Method</p>'
			|| '<p><table>'
			|| '<tr><td class="evenRow">Preferred Ride Times</td><td class="evenRow">' || 
				carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || '</td></tr>'
			|| '<tr><td class="oddRow">Pick-up location</td><td class="oddRow">' 
			|| COALESCE(v_rider_record."RiderCollectionStreetNumber", '' ) || ' ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="evenRow">Destination</td><td class="evenRow">' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || v_rider_record."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN v_rider_record."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN v_rider_record."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || v_rider_record."RiderAccommodationNotes" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>If you can no longer drive ' || v_driver_record."DriverFirstName" || ', please let us know and '
			|| '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-driver-match?UUID_driver=' || uuid_driver 
			|| '&UUID_rider=' || uuid_rider 
			|| '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName" ) || '">cancel this ride match only</a></p>'
			|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=driver&uuid=' || v_driver_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p><a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || v_driver_record."UUID" || '&DriverPhone=' || carpoolvote.urlencode(v_driver_record."DriverLastName") ||  '">Cancel this Drive Offer</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';

			v_body := v_html_header || v_html_body || v_html_footer;

			INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
			VALUES (v_driver_record."DriverEmail", uuid_driver, v_subject, v_body);
		END IF;
		
		IF v_driver_record."DriverPhone" IS NOT NULL AND (position('SMS' in v_driver_record."DriverPreferredContact") > 0)
		THEN
		
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Match is confirmed.' || ' ' || chr(10)
					|| ' Rider ' ||  v_rider_record."RiderFirstName" || ' ' || v_rider_record."RiderLastName"
					|| ' is now waiting for you to get in touch to arrange the details of the ride.'
					|| ' Please contact the rider as soon as possible.' || chr(10)
					|| CASE WHEN v_rider_record."RiderEmail" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%Email%',false) THEN '(preferred)' else ' ' END || 'Email: ' || v_rider_record."RiderEmail"  ELSE ' ' END || chr(10)
					|| CASE WHEN v_rider_record."RiderPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%Phone%',false) THEN '(preferred)' else ' ' END || 'Phone: ' || v_rider_record."RiderPhone"  ELSE ' ' END || chr(10)
					|| CASE WHEN v_rider_record."RiderPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_rider_record."RiderPreferredContact" LIKE '%SMS%',false) THEN '(preferred)' else ' ' END || 'SMS/Text: ' || v_rider_record."RiderPhone"  ELSE ' ' END || chr(10)
					|| ' Pick-up location : ' || COALESCE(v_rider_record."RiderCollectionStreetNumber", '' ) || ' ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') 
					|| v_rider_record."RiderCollectionZIP" || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal");
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_driver_record."DriverPhone", uuid_driver, v_body, carpoolvote.outgoing_sms_insert_status(v_driver_record."DriverPhone"));
		END IF;		

		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_driver_match_confirmed_by_driver(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_driver_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_driver_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) TO carpool_admins;

---------------------------------------------------------------------
-- USER STORY 015
-- Email/SMS notifications to rider for confirmed match by driver
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.notify_rider_match_confirmed_by_driver(
	uuid_driver character varying(50),
	uuid_rider character varying(50),
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$                                                                                                                  
DECLARE                               
	v_driver_record carpoolvote.driver%ROWTYPE;
	v_rider_record carpoolvote.rider%ROWTYPE;
	v_subject carpoolvote.outgoing_email.subject%TYPE;                                                                            
	v_body carpoolvote.outgoing_email.body%TYPE;                                                                                  
	v_html_header carpoolvote.outgoing_email.body%TYPE;
	v_html_body carpoolvote.outgoing_email.body%TYPE;
	v_html_footer carpoolvote.outgoing_email.body%TYPE;
 
BEGIN                                                                                                                      
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';
	BEGIN
		v_html_header := carpoolvote.notifications_html_header();
		v_html_footer := carpoolvote.notifications_html_footer();

		SELECT * INTO v_driver_record FROM carpoolvote.driver WHERE "UUID" = uuid_driver;
		SELECT * INTO v_rider_record FROM carpoolvote.rider WHERE "UUID" = uuid_rider;

		IF v_rider_record."RiderEmail" IS NOT NULL
		THEN
		
		    -- notification to the rider
			v_subject := 'You have been matched with a driver!   --- [' || v_rider_record."UUID" || ']';
			v_html_body := '<body>'
			|| '<p>Dear ' || v_rider_record."RiderFirstName" ||  ' ' || v_rider_record."RiderLastName" || ', <p>' 
			|| '<p>Great news - a driver has accepted your request for a ride!</p>'
			|| '<p>' || v_driver_record."DriverFirstName" || ' ' || v_driver_record."DriverLastName" 
			|| ' will get in touch to arrange the details of the ride.</p>'
			|| '<p>If you DO NOT hear from ' || v_driver_record."DriverFirstName" || ', please feel free to reach out :<br/>'
			|| CASE WHEN v_driver_record."DriverEmail" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_driver_record."DriverPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || 'Email: ' || v_driver_record."DriverEmail"  ELSE ' ' END || '<br/>'
			|| CASE WHEN v_driver_record."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_driver_record."DriverPreferredContact" LIKE '%Phone%',false) THEN '(*)' else ' ' END || 'Phone: ' || v_driver_record."DriverPhone"  ELSE ' ' END || '<br/>'
			|| CASE WHEN v_driver_record."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_driver_record."DriverPreferredContact" LIKE '%SMS%',false) THEN '(*)' else ' ' END || 'SMS/Text: ' || v_driver_record."DriverPhone"  ELSE ' ' END || '<br/>'
			|| '(*) = Preferred Method</p>'
			|| '<p>Driver License Plate : ' || COALESCE(v_driver_record."DriverLicenseNumber", 'N/A') || ' (Please check before getting in)</p>'
			|| '<p>If you would prefer to have a different driver, please let us know, and '
			|| '<a href="' || 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-rider-match?UUID_driver=' || uuid_driver 
			|| '&UUID_rider=' || uuid_rider 
			|| '&RiderPhone=' || carpoolvote.urlencode( v_rider_record."RiderLastName") || '">cancel this ride match only</a></p>'   -- yes, this is correct, the API uses RiderPhone as parameter, and one can pass a phone number or a last name
			|| '<p>To view or manage your matches, visit our <a href="' || COALESCE(carpoolvote.get_param_value('site.base.url'), 'http://carpoolvote.com') || '/self-service/?type=rider&uuid=' || v_rider_record."UUID" || '">Self-Service Portal</a></p>'
			|| '<p>If you no longer need a ride, you please <a href="'|| 'https://api.carpoolvote.com/' || COALESCE(carpoolvote.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || v_rider_record."UUID" || '&RiderPhone=' || carpoolvote.urlencode(v_rider_record."RiderLastName") ||  '">cancel this Ride Request</a></p>'
			|| '<p>Warm wishes</p>'
			|| '<p>The CarpoolVote.com team.</p>'
			|| '</body>';
		
			v_body := v_html_header || v_html_body || v_html_footer;
		
			INSERT INTO carpoolvote.outgoing_email (recipient, uuid, subject, body)
			VALUES (v_rider_record."RiderEmail", uuid_rider, v_subject, v_body);
		END IF;
		
		IF v_rider_record."RiderPhone" IS NOT NULL AND (position('SMS' in v_rider_record."RiderPreferredContact") > 0)
		THEN
			v_body := 'From CarpoolVote.com' || ' ' || chr(10)
					|| ' Match is confirmed by driver. No further action needed.'|| ' ' || chr(10)
					|| ' Driver : ' ||  v_driver_record."DriverFirstName" || ' ' || v_driver_record."DriverLastName" || ' ' || ' ' || chr(10)
					|| CASE WHEN v_driver_record."DriverEmail" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_driver_record."DriverPreferredContact" LIKE '%Email%',false) THEN '(*)' else ' ' END || 'Email: ' || v_driver_record."DriverEmail"  ELSE ' ' END || chr(10)
					|| CASE WHEN v_driver_record."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_driver_record."DriverPreferredContact" LIKE '%Phone%',false) THEN '(*)' else ' ' END || 'Phone: ' || v_driver_record."DriverPhone"  ELSE ' ' END || chr(10)
					|| CASE WHEN v_driver_record."DriverPhone" IS NOT NULL THEN '- ' || CASE WHEN coalesce(v_driver_record."DriverPreferredContact" LIKE '%SMS%',false) THEN '(*)' else ' ' END || 'SMS/Text: ' || v_driver_record."DriverPhone"  ELSE ' ' END || chr(10)
					|| ' Driver License Plate : ' || COALESCE(v_driver_record."DriverLicenseNumber", 'N/A') || ' (Please check before getting in)' ||chr(10)
					|| ' Pick-up location : ' 
					|| COALESCE(v_rider_record."RiderCollectionStreetNumber", '' ) || ' ' || COALESCE(v_rider_record."RiderCollectionAddress" || ', ', '') || v_rider_record."RiderCollectionZIP" || ' ' || ' ' || chr(10)
					|| ' Destination : ' || COALESCE(v_rider_record."RiderDestinationAddress" || ', ', '') || v_rider_record."RiderDropOffZIP" || ' ' || ' ' || chr(10)
					|| ' Party Size : ' || v_rider_record."TotalPartySize" || ' ' || chr(10)
					|| ' Preferred Ride Times : ' || carpoolvote.convert_datetime_to_local_format(v_rider_record."AvailableRideTimesLocal") || ' ' || chr(10)
					|| ' User support : 540-656-9388 ';
			
				INSERT INTO carpoolvote.outgoing_sms (recipient, uuid, body, status)
				VALUES (v_rider_record."RiderPhone", uuid_rider, v_body, carpoolvote.outgoing_sms_insert_status(v_rider_record."RiderPhone"));
		END IF;		

		RETURN;
	
	EXCEPTION WHEN OTHERS
	THEN
		out_error_code := carpoolvote.f_EXECUTION_ERROR();
		out_error_text := 'Unexpected exception in notify_rider_match_confirmed_by_driver(' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.notify_rider_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.notify_rider_match_confirmed_by_driver(character varying, character varying, OUT integer, out text) TO carpool_admins;
