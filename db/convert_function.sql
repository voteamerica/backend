DO
$$
DECLARE

ride_times text[];
start_time timestamp without time zone;
end_time timestamp without time zone;
time_elem text;

start_time_txt text;
end_time_txt text;

BEGIN

ride_times := string_to_array('2016-10-01T02:00/2016-10-01T03:00|2018-12-01T18:00/2018-12-01T19:00', '|');
FOREACH time_elem IN ARRAY ride_times
LOOP
	-- each time interval is in ISO8601 format					
	-- new format without timezone : 2016-10-01T02:00/2016-10-01T03:00
	start_time :=  (substring(time_elem from 1 for (position ('/' in time_elem)-1)))::timestamp without time zone;
	end_time :=    (substring(time_elem from position ('/' in time_elem)))::timestamp without time zone;



	RAISE NOTICE 'start=%', to_char(start_time, 'YYYY/MM/DD HH12:MI AM');
	RAISE NOTICE 'end=%', to_char(end_time, 'YYYY/MM/DD HH12:MI AM');
END LOOP;
END
$$