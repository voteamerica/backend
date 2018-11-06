-- from fct_utilities.sql

-- return codes : 
-- -1 : ERROR - Generic Error
-- 0  : SUCCESS
-- 2  : ERROR - Input validation
CREATE OR REPLACE FUNCTION carpoolvote.validate_availabletimeslocal(availableTimesLocal character varying,
	OUT out_error_code INTEGER,
	OUT out_error_text TEXT) AS
$BODY$
DECLARE
	available_times_arr text[];
	a_time_elem text;
	start_time timestamp without time zone;
	end_time timestamp without time zone;
	time_now_pst timestamp without time zone;
	b_all_times_expired boolean := TRUE;
BEGIN

	select carpoolvote.f_SUCCESS() into out_error_code;
	out_error_text := '';

	BEGIN

		IF (availableTimesLocal is null) or (length(availableTimesLocal) = 0) THEN
			select carpoolvote.f_INPUT_VAL_ERROR() into out_error_code;
			out_error_text := 'Invalid AvailableTimesLocal: ' || availableTimesLocal;
			RETURN;
		END IF;
		
		
		-- split AvailableDriveTimesLocal in individual time intervals
 		-- FORMAT should be like this 
 		-- 2016-10-01T02:00/2016-10-01T03:00|2016-10-01T02:00/2016-10-01T03:00|2016-10-01T02:00/2016-10-01T03:00
 		available_times_arr := string_to_array(availableTimesLocal, '|');
		b_all_times_expired := TRUE;
 		FOREACH a_time_elem IN ARRAY available_times_arr
		LOOP
			BEGIN
				-- each time interval is in ISO8601 format
				-- new format without timezone : 2016-10-01T02:00/2016-10-01T03:00
				start_time :=  (substring(a_time_elem from 1 for (position ('/' in a_time_elem)-1)))::timestamp without time zone;
				end_time :=    (substring(a_time_elem from position ('/' in a_time_elem)))::timestamp without time zone;
			
				IF start_time > end_time
				THEN
					select carpoolvote.f_INPUT_VAL_ERROR() into out_error_code;
					out_error_text := 'Invalid value in AvailableDriveTimes:' || a_time_elem;
					RETURN;
				ELSE
					SELECT now() AT TIME ZONE 'PST' into time_now_pst;

					IF end_time > time_now_pst   ----   --[NOW]--[S]--[E]   : not expired
					THEN                        ----   --[S]---[NOW]--[E]  : not expired
					   							       --[S]--[E]----[NOW] : expired
						b_all_times_expired := FALSE;
					END IF;
				END IF;
							
			EXCEPTION WHEN OTHERS
			THEN
				select carpoolvote.f_INPUT_VAL_ERROR() into out_error_code;
				out_error_text := 'Invalid value in AvailableTimes :' || a_time_elem;
				RETURN;
			END;
		
			IF b_all_times_expired
			THEN
				select carpoolvote.f_INPUT_VAL_ERROR() into out_error_code;
				out_error_text := 'All AvailableTimes are expired';
				RETURN;
			END IF;		
		END LOOP;
		RETURN;
	EXCEPTION WHEN OTHERS
	THEN
		select carpoolvote.f_EXECUTION_ERROR() into out_error_code;
		out_error_text := 'Unexpected exception (' || SQLSTATE || ')' || SQLERRM;
		RETURN;
	END;

END  
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.validate_availabletimeslocal(
	character varying, out integer, out text)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.validate_availabletimeslocal(
    character varying, out integer, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.validate_availabletimeslocal(
	character varying, out integer, out text) TO carpool_role;
