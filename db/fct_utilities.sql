SET search_path = carpoolvote, pg_catalog;

CREATE OR REPLACE FUNCTION carpoolvote.f_SUCCESS() RETURNS INTEGER AS
$BODY$
BEGIN
	RETURN 0;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE
  COST 100;
  
ALTER FUNCTION carpoolvote.f_SUCCESS()  OWNER TO carpool_admins;
REVOKE ALL ON FUNCTION f_SUCCESS() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_SUCCESS() TO carpool_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_SUCCESS() TO carpool_web_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_SUCCESS() TO carpool_admins;


CREATE OR REPLACE FUNCTION carpoolvote.f_EXECUTION_ERROR() RETURNS INTEGER AS
$BODY$
BEGIN
	RETURN -1;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE
  COST 100;
  
ALTER FUNCTION carpoolvote.f_EXECUTION_ERROR()  OWNER TO carpool_admins;
REVOKE ALL ON FUNCTION f_EXECUTION_ERROR() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_EXECUTION_ERROR() TO carpool_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_EXECUTION_ERROR() TO carpool_web_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_EXECUTION_ERROR() TO carpool_admins;


CREATE OR REPLACE FUNCTION carpoolvote.f_INPUT_DISABLED() RETURNS INTEGER AS
$BODY$
BEGIN
	RETURN 1;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE
  COST 100;
  
ALTER FUNCTION carpoolvote.f_INPUT_DISABLED()  OWNER TO carpool_admins;
REVOKE ALL ON FUNCTION f_INPUT_DISABLED() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_INPUT_DISABLED() TO carpool_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_INPUT_DISABLED() TO carpool_web_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_INPUT_DISABLED() TO carpool_admins;

CREATE OR REPLACE FUNCTION carpoolvote.f_INPUT_VAL_ERROR() RETURNS INTEGER AS
$BODY$
BEGIN
	RETURN 2;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE
  COST 100;
  
ALTER FUNCTION carpoolvote.f_INPUT_VAL_ERROR()  OWNER TO carpool_admins;
REVOKE ALL ON FUNCTION f_INPUT_VAL_ERROR() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_INPUT_VAL_ERROR() TO carpool_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_INPUT_VAL_ERROR() TO carpool_web_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.f_INPUT_VAL_ERROR() TO carpool_admins;
  

CREATE OR REPLACE FUNCTION carpoolvote.urlencode(in_str text, OUT _result text)
    STRICT IMMUTABLE AS $urlencode$
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
$urlencode$ LANGUAGE plpgsql;


ALTER FUNCTION carpoolvote.urlencode(text, out text)  OWNER TO carpool_admins;
REVOKE ALL ON FUNCTION urlencode(in_str text, OUT _result text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION  carpoolvote.urlencode(text, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.urlencode(text, out text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.urlencode(text, out text) TO carpool_admins;


CREATE OR REPLACE FUNCTION carpoolvote.get_param_value(a_param_name character varying)
  RETURNS character varying AS
$BODY$
DECLARE

v_env carpoolvote.params.value%TYPE;

BEGIN
	v_env := NULL;
	SELECT value INTO v_env FROM carpoolvote.params WHERE name=a_param_name;

RETURN v_env;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.get_param_value(character varying)
  OWNER TO carpool_admins;
REVOKE ALL ON FUNCTION get_param_value(a_param_name character varying) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION carpoolvote.get_param_value(character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.get_param_value(character varying) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.get_param_value(character varying) TO carpool_admins;


--
-- Name: distance(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: carpoolvote; Owner: carpool_admins
--

CREATE OR REPLACE FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) RETURNS double precision
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
-- Name: distance(double precision, double precision, double precision, double precision); Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--

REVOKE ALL ON FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM PUBLIC;
REVOKE ALL ON FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) FROM carpool_admins;
GRANT ALL ON FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_admins;
GRANT ALL ON FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_role;


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
					IF end_time > now()   ----   --[NOW]--[S]--[E]   : not expired
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

----------------------------------------------------------
-- Converts available ride/drive times 
-- from internal representation
-- to localized format, read from carpoolvote.params table 
-- (notifications.datetime.format)
-- input : 
-- 2016-10-01T02:00/2016-10-01T03:00|2018-12-01T18:00/2018-12-01T19:00
-- output :
-- Oct 7 02:00am-03:00am, Dec 7 06:00pm-07:00pm
----------------------------------------------------------
CREATE OR REPLACE FUNCTION carpoolvote.convert_datetime_to_local_format(
	in_date_string TEXT ) 
RETURNS TEXT AS
$BODY$
DECLARE

ride_times text[];
start_time timestamp without time zone;
end_time timestamp without time zone;
time_elem text;

start_time_txt text;
end_time_txt text;
v_time_format text;
v_date_format text;
v_output text;

BEGIN
	v_output := '';

	SELECT COALESCE(carpoolvote.get_param_value('notifications.time.format'), 'HH12:MIam') INTO v_time_format;
	SELECT COALESCE(carpoolvote.get_param_value('notifications.date.format'), 'MM/DD/YY') INTO v_date_format;
	
	--RAISE NOTICE 'v_time_format=%', v_time_format;
	--RAISE NOTICE 'v_date_format=%', v_date_format;

	ride_times := string_to_array(in_date_string, '|');
	FOREACH time_elem IN ARRAY ride_times
	LOOP
		-- each time interval is in ISO8601 format					
		-- new format without timezone : 2016-10-01T02:00/2016-10-01T03:00
		start_time :=  (substring(time_elem from 1 for (position ('/' in time_elem)-1)))::timestamp without time zone;
		end_time :=    (substring(time_elem from position ('/' in time_elem)))::timestamp without time zone;

		v_output := v_output || ', ' 
		|| to_char(start_time, v_date_format || ' ' || v_time_format ) || '-' 
		|| to_char(end_time, v_time_format);
		--RAISE NOTICE 'start=%', to_char(start_time, v_time_format );
		--RAISE NOTICE 'end=%', to_char(end_time, v_time_format);
	END LOOP;

	return substr(v_output,3);
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION carpoolvote.convert_datetime_to_local_format(text) OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.convert_datetime_to_local_format(text) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION carpoolvote.convert_datetime_to_local_format(text) TO carpool_role;
