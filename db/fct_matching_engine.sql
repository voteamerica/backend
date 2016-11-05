CREATE OR REPLACE FUNCTION nov2016.perform_match()
  RETURNS character varying AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.perform_match()
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.perform_match() TO carpool_role;
