DROP FUNCTION nov2016.queue_email_notif() cascade;

CREATE OR REPLACE FUNCTION nov2016.queue_email_notif()
  RETURNS trigger AS
$BODY$                                                                                                                  
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
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=driver&uuid=' || NEW."UUID" || '">Self-Service Portal</a></p>'
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
            v_body :=  'From CarpoolVote.com' || ' ' || nov2016.urlencode(chr(10))
					|| ' Driver offer received! Ref: ' || NEW."UUID" || ' ' || nov2016.urlencode(chr(10))
					|| ' Pick-up ZIP : ' || NEW."DriverCollectionZIP" || ' ' || nov2016.urlencode(chr(10))
					|| ' Radius : ' || NEW."DriverCollectionRadius" || ' ' || nov2016.urlencode(chr(10))
					|| ' Drive Times  : ' || replace(replace(replace(replace(replace(NEW."AvailableDriveTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || ' ' || nov2016.urlencode(chr(10))
					|| ' Seats : ' || NEW."SeatCount" || ' ' || nov2016.urlencode(chr(10))
					|| ' Wheelchair accessible : ' || CASE WHEN NEW."DriverCanLoadRiderWithWheelchair" THEN 'Yes' ELSE 'No' END || ' ' || nov2016.urlencode(chr(10))
					|| ' Phone Number : ' || NEW."DriverPhone" || ' ' || nov2016.urlencode(chr(10))
					|| ' Self-Service portal : http://carpoolvote.com/self-service/?type=driver&uuid=' || NEW."UUID" || ' ' || nov2016.urlencode(chr(10))
					|| ' Cancel : https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-drive-offer?UUID=' || NEW."UUID" || '&DriverPhone=' || nov2016.urlencode(NEW."DriverLastName");
					
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
			|| '<tr><td class="oddRow">Pick-up Address</td><td class="oddRow">' || COALESCE(NEW."RiderCollectionAddress", ' ') || '</td></tr>'
			|| '<tr><td class="evenRow">Pick-up ZIP</td><td class="evenRow">' || NEW."RiderCollectionZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Destination Address</td><td class="oddRow">' || COALESCE(NEW."RiderDestinationAddress", ' ') || '</td></tr>'
			|| '<tr><td class="evenRow">Destination ZIP</td><td class="evenRow">' || NEW."RiderDropOffZIP" || '</td></tr>'
			|| '<tr><td class="oddRow">Party Size</td><td class="oddRow">' || NEW."TotalPartySize" || '</td></tr>'
			|| '<tr><td class="evenRow">Wheelchair accessibility needed</td><td class="evenRow">' || CASE WHEN NEW."NeedWheelchair" THEN 'Yes' ELSE 'No' END || '</td></tr>'
			|| '<tr><td class="oddRow">Two-way trip needed</td><td class="oddRow">' ||  CASE WHEN NEW."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END  || '</td></tr>'
			|| '<tr><td class="evenRow">Notes</td><td class="evenRow">' || NEW."RiderAccommodationNotes" || '</td></tr>'
			|| '<tr><td class="oddRow">Phone Number</td><td class="oddRow">' || NEW."RiderPhone" || '</td></tr>'
			|| '<tr><td class="evenRow">Email</td><td class="evenRow">' || NEW."RiderEmail" || '</td></tr>'
			|| '</table>'
			|| '</p>'
			|| '<p>To view or manage your matches, visit our <a href="http://carpoolvote.com/self-service/?type=rider&uuid=' || NEW."UUID" || '">Self-Service Portal</a></p>'
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
            v_body := 'From CarpoolVote.com' || ' ' || nov2016.urlencode(chr(10)) 
					|| ' Ride Request received! Ref: ' || NEW."UUID" || ' ' || nov2016.urlencode(chr(10))
					|| ' Preferred Ride Times : ' || replace(replace(replace(replace(replace(NEW."AvailableRideTimesLocal", '|', ','), 'T', ' '), '/', '>'), '-','/'), '>', '-') || ' ' || nov2016.urlencode(chr(10))
					|| ' Pick-up : ' || COALESCE(NEW."RiderCollectionAddress" || ', ', '') || NEW."RiderCollectionZIP" || ' ' || nov2016.urlencode(chr(10))
					|| ' Destination : ' || COALESCE(NEW."RiderDestinationAddress" || ', ', '') || NEW."RiderDropOffZIP" || ' ' || nov2016.urlencode(chr(10))
					|| ' Party Size : ' || NEW."TotalPartySize" || ' ' || nov2016.urlencode(chr(10))
					|| ' Wheelchair accessibility needed : ' ||  CASE WHEN NEW."NeedWheelchair" THEN 'Yes' ELSE 'No' END || ' ' || nov2016.urlencode(chr(10))
					|| ' Two-way trip needed : ' ||  CASE WHEN NEW."TwoWayTripNeeded" THEN 'Yes' ELSE 'No' END || ' ' || nov2016.urlencode(chr(10))
					|| ' Notes : ' ||  NEW."RiderAccommodationNotes" || ' ' || nov2016.urlencode(chr(10))
					|| ' Phone Number : ' ||  NEW."RiderPhone" || ' ' || nov2016.urlencode(chr(10))
					|| ' Self-Service portal : http://carpoolvote.com/self-service/?type=rider&uuid=' || NEW."UUID" || ' ' || nov2016.urlencode(chr(10))
					|| ' Cancel : https://api.carpoolvote.com/' || COALESCE(nov2016.get_param_value('api_environment'), 'live') || '/cancel-ride-request?UUID=' || NEW."UUID" || '&RiderPhone=' || nov2016.urlencode(NEW."RiderLastName");
				
            INSERT INTO nov2016.outgoing_sms (recipient, body)                                             
            VALUES (NEW."RiderPhone", v_body);                                                                 
        END IF;                    
		
    END IF;                                                                                                                

    RETURN NEW;                                                                                                            
END;    
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.queue_email_notif()
  OWNER TO carpool_admins;


  
CREATE TRIGGER send_email_notif_ins_driver_trg AFTER INSERT ON stage.websubmission_driver FOR EACH ROW EXECUTE PROCEDURE nov2016.queue_email_notif();
CREATE TRIGGER send_email_notif_ins_rider_trg AFTER INSERT ON stage.websubmission_rider FOR EACH ROW EXECUTE PROCEDURE nov2016.queue_email_notif();


REVOKE ALL ON SEQUENCE nov2016.outgoing_sms_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE nov2016.outgoing_sms_id_seq FROM carpool_admins;
GRANT ALL ON SEQUENCE nov2016.outgoing_sms_id_seq TO carpool_admins;
GRANT SELECT,USAGE ON SEQUENCE nov2016.outgoing_sms_id_seq TO carpool_web;
