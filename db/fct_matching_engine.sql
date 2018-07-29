CREATE OR REPLACE FUNCTION carpoolvote.perform_match(OUT out_error_code integer, OUT out_error_text text)
AS
$BODY$
DECLARE

v_temp_error_code integer := 0;
v_temp_error_text text := '';

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
BEYOND_RADIUS_TOLERANCE integer := 10;

drive_offer_row carpoolvote.driver%ROWTYPE;
ride_request_row carpoolvote.rider%ROWTYPE;
cnt integer;
v_score integer;
v_existing_score integer;
v_pair_rank integer;
v_status text;

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

v_record record;

BEGIN
	out_error_code := carpoolvote.f_SUCCESS();
	out_error_text := '';

	RADIUS_MAX_ALLOWED := COALESCE(carpoolvote.get_param_value('radius.max'), '100')::int;
	BEYOND_RADIUS_TOLERANCE := COALESCE(carpoolvote.get_param_value('radius.tolerance'), '10')::int;

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
		BEGIN
			CREATE TEMPORARY TABLE match_notifications_buffer (
		 		uuid_driver character varying(50) NOT NULL,
		 		uuid_rider character varying(50) NOT NULL
			);
		EXCEPTION WHEN OTHERS
		THEN
			DELETE FROM match_notifications_buffer;
		END;
	
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
				-- RiderCollectionZIP
				-- RiderDropOffZIP
			
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
				
						v_score := 0;
						v_pair_rank := 2;

						-- vulnerable rider matching
						IF ride_request_row."RiderIsVulnerable" = false
						THEN
							v_pair_rank := v_pair_rank +1;
						ELSIF ride_request_row."RiderIsVulnerable" = true 
							AND drive_offer_row."DrivingOnBehalfOfOrganization" 
						THEN
							v_pair_rank := v_pair_rank +1;
						END IF;
						
						
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
						
						IF distance_origin_pickup < (drive_offer_row."DriverCollectionRadius" + BEYOND_RADIUS_TOLERANCE)
							AND distance_origin_dropoff < (drive_offer_row."DriverCollectionRadius" + BEYOND_RADIUS_TOLERANCE)
						THEN
							IF v_pair_rank = 3
							THEN
								v_pair_rank := 4;
							END IF;
							v_score = distance_origin_pickup;
			
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
									-- new format without timezone : 2016-10-01T02:00/2016-10-01T03:00
									start_drive_time :=  (substring(driver_time from 1 for (position ('/' in driver_time)-1)))::timestamp without time zone;
									end_drive_time :=    (substring(driver_time from position ('/' in driver_time)))::timestamp without time zone;

									
									
									
									IF end_drive_time < start_ride_time       -- [ddddd]  [rrrrrr]
										OR end_ride_time < start_drive_time   -- [rrrrr]  [dddddd]
									THEN
										-- we're totally disconnected
										
										-- If driver has the ability to carry a rider who needs a wheelchair,
										-- and if they're both willing to drive/ride the same day (no matter the time)
										-- then we grant them rank 5
										
										IF ride_request_row."NeedWheelchair" = true AND drive_offer_row."DriverCanLoadRiderWithWheelchair" = true 
											AND EXTRACT(DOY FROM start_ride_time) = EXTRACT(DOY FROM start_drive_time)
										THEN
											IF v_pair_rank = 4
											THEN
												v_pair_rank := 5;
											END IF;
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
									ELSE
										IF v_pair_rank = 4
										THEN
											v_pair_rank := 5;
										END IF;
									END IF;
									
                                    
									--RAISE NOTICE 'D-%, R-%, time ranking ranking Score=%', 
										--drive_offer_row."UUID", 
										--ride_request_row."UUID", 
										--v_score;
										
									IF v_pair_rank >= 4
									THEN
									
										IF v_pair_rank = 4
										THEN
											v_status='ExtendedMatch';
										ELSE
											v_status='MatchProposed';
										END IF;
									
                                        IF EXISTS (
                                            SELECT 1 FROM carpoolvote.match
                                                WHERE uuid_rider = ride_request_row."UUID"
                                                AND uuid_driver = drive_offer_row."UUID")
                                        THEN
											-- maybe new match is higher rank
											UPDATE carpoolvote.match
                                            SET status = v_status
                                            WHERE uuid_rider = ride_request_row."UUID"
                                            AND uuid_driver = drive_offer_row."UUID"
                                            AND status <> 'MatchProposed' AND status <> v_status;
                                            
											IF FOUND THEN
												v_proposed_count := v_proposed_count +1;
                                                RAISE NOTICE 'Better Match, Rider=%, Driver=%, Score=%, Rank=%',
														ride_request_row."UUID", drive_offer_row."UUID", v_score, v_pair_rank;
											END IF;
                                                
                                        
                                        ELSE
											INSERT INTO carpoolvote.match (uuid_rider, uuid_driver, score, status)
												VALUES (
													ride_request_row."UUID",               --pkey
													drive_offer_row."UUID",                --pkey 
													v_score,
													v_status
												);

											IF v_status = 'MatchProposed'
											THEN
											
												INSERT INTO match_notifications_buffer (uuid_driver, uuid_rider)
                                                VALUES (drive_offer_row."UUID", ride_request_row."UUID");

												UPDATE carpoolvote.rider r
												SET status='MatchProposed'
												WHERE r."UUID" = ride_request_row."UUID";

												-- If already MatchConfirmed, keep it as is
												UPDATE carpoolvote.driver d
												SET status='MatchProposed'
												WHERE d."UUID" = drive_offer_row."UUID"
                                                AND status='Pending';
											
												v_proposed_count := v_proposed_count +1;
                                            
												RAISE NOTICE 'Proposed Match, Rider=%, Driver=%, Score=%, Rank=%',
													ride_request_row."UUID", drive_offer_row."UUID", v_score, v_pair_rank;
											ELSE
												RAISE NOTICE 'Extended Match, Rider=%, Driver=%, Score=%, Rank=%',
													ride_request_row."UUID", drive_offer_row."UUID", v_score, v_pair_rank;
											END IF;
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

		-- send notifications to driver only. Riders will be waiting to be contacted
		FOR v_record IN SELECT DISTINCT uuid_driver FROM match_notifications_buffer
		LOOP
				
			SELECT * FROM carpoolvote.notify_driver_new_available_matches(v_record.uuid_driver) INTO v_temp_error_code, v_temp_error_text;
			IF v_temp_error_code <> carpoolvote.f_SUCCESS()
			THEN
				out_error_code := carpoolvote.f_EXECUTION_ERROR();
				out_error_text := out_error_text || ' | ' || v_temp_error_text;
				RAISE NOTICE 'Error while generating notifications for uuid=% : %', v_record.uuid_driver, v_temp_error_text; 
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
	
	RETURN;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.perform_match(OUT integer, OUT text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.perform_match(OUT integer, OUT text) TO carpool_role;
REVOKE ALL ON FUNCTION carpoolvote.perform_match(OUT integer, OUT text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION carpoolvote.perform_match(OUT integer, OUT text) TO carpool_admins;



