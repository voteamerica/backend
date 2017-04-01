-- Function: carpoolvote.driver_exists(character varying, character varying)

-- DROP FUNCTION carpoolvote.driver_exists(character varying, character varying);

CREATE OR REPLACE FUNCTION carpoolvote.driver_exists(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_exists(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_exists(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_exists(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_exists(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_exists(character varying, character varying) TO carpool_role;


-- Function: carpoolvote.rider_exists(character varying, character varying)

-- DROP FUNCTION carpoolvote.rider_exists(character varying, character varying);

CREATE OR REPLACE FUNCTION carpoolvote.rider_exists(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.rider_exists(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_exists(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_exists(character varying, character varying) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_exists(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_exists(character varying, character varying) TO public;


CREATE OR REPLACE FUNCTION carpoolvote.rider_info(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS json AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.rider_info(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_info(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_info(character varying, character varying) TO carpool_role;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_info(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_info(character varying, character varying) TO public;


-- Function: carpoolvote.driver_info(character varying, character varying)

-- DROP FUNCTION carpoolvote.driver_info(character varying, character varying);

CREATE OR REPLACE FUNCTION carpoolvote.driver_info(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS json AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.driver_info(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_info(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_info(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_info(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_info(character varying, character varying) TO carpool_role;

DROP VIEW carpoolvote.vw_driver_matches;

CREATE VIEW carpoolvote.vw_driver_matches 
AS
    SELECT 
        carpoolvote.match."state" AS "matchState", 
    "uuid_driver", "uuid_rider", "score", "UUID", "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail", "RiderPhone", "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesUTC", "TotalPartySize", "TwoWayTripNeeded", "RiderIsVulnerable", "RiderWillNotTalkPolitics", "PleaseStayInTouch", "NeedWheelchair", "RiderPreferredContact", "RiderAccommodationNotes", "RiderLegalConsent", "ReadyToMatch", 
    carpoolvote.rider."state", 
    "state_info", "RiderWillBeSafe", "AvailableRideTimesLocal", "RiderCollectionAddress", "RiderDestinationAddress"
 FROM carpoolvote.match
    INNER JOIN 
        carpoolvote.rider on 
        carpoolvote.rider."UUID" = carpoolvote.match.uuid_rider;

ALTER TABLE carpoolvote.vw_driver_matches
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_driver_matches TO carpool_admins;
GRANT SELECT, UPDATE, INSERT ON TABLE carpoolvote.vw_driver_matches TO carpool_web_role;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE carpoolvote.vw_driver_matches TO carpool_role;
GRANT SELECT ON carpoolvote.vw_driver_matches TO carpool_web;


DROP VIEW carpoolvote.vw_rider_matches;

CREATE VIEW carpoolvote.vw_rider_matches 
AS
--     SELECT 
--         carpoolvote.match."state" AS "matchState", 
--     "uuid_driver", "uuid_rider", "score", "UUID", "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail", "RiderPhone", "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesUTC", "TotalPartySize", "TwoWayTripNeeded", "RiderIsVulnerable", "RiderWillNotTalkPolitics", "PleaseStayInTouch", "NeedWheelchair", "RiderPreferredContact", "RiderAccommodationNotes", "RiderLegalConsent", "ReadyToMatch", 
--     carpoolvote.rider."state", 
--     "state_info", "RiderWillBeSafe", "AvailableRideTimesLocal", "RiderCollectionAddress", "RiderDestinationAddress"
--  FROM carpoolvote.match
--     INNER JOIN 
--         carpoolvote.rider on 
--         carpoolvote.rider."UUID" = carpoolvote.match.uuid_rider;


	SELECT 
carpoolvote.match."state" AS "matchState", "uuid_driver", "uuid_rider", "score", "UUID", "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", "AvailableDriveTimesUTC", "DriverCanLoadRiderWithWheelchair", "SeatCount", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", "DriverEmail", "DriverPhone", "DrivingOnBehalfOfOrganization", "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics", "ReadyToMatch", "PleaseStayInTouch", 
carpoolvote.driver."state", 
"state_info", "DriverPreferredContact", "DriverWillTakeCare", "AvailableDriveTimesLocal"
	FROM carpoolvote.match
    INNER JOIN 
        carpoolvote.driver on 
        carpoolvote.driver."UUID" = carpoolvote.match.uuid_driver;

ALTER TABLE carpoolvote.vw_rider_matches
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_rider_matches TO carpool_admins;
GRANT SELECT, UPDATE, INSERT ON TABLE carpoolvote.vw_rider_matches TO carpool_web_role;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE carpoolvote.vw_rider_matches TO carpool_role;
GRANT SELECT ON carpoolvote.vw_rider_matches TO carpool_web;



-- Function: carpoolvote.driver_proposed_matches(character varying, character varying)

-- DROP FUNCTION carpoolvote.driver_proposed_matches(character varying, character varying);

CREATE OR REPLACE FUNCTION carpoolvote.driver_proposed_matches(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS setof json AS
$BODY$

-- DECLARE                                                   
--BEGIN 

        SELECT row_to_json(s)
        FROM ( 
            SELECT * from
            carpoolvote.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchState" = 'MatchProposed'
        ) s ;

--END  

$BODY$
--   LANGUAGE plpgsql VOLATILE
    LANGUAGE sql stable
  COST 100;
ALTER FUNCTION carpoolvote.driver_proposed_matches(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_proposed_matches(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_proposed_matches(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_proposed_matches(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_proposed_matches(character varying, character varying) TO carpool_role;

-- Function: carpoolvote.driver_confirmed_matches(character varying, character varying)

-- DROP FUNCTION carpoolvote.driver_confirmed_matches(character varying, character varying);

CREATE OR REPLACE FUNCTION carpoolvote.driver_confirmed_matches(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS setof json AS
$BODY$

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
    --         AND "matchState" = 'MatchConfirmed';
    --         -- AND "matchState" = 'Canceled';

    --    RETURN row_to_json(d_row);

        SELECT row_to_json(s)
        FROM ( 
            SELECT * from
            carpoolvote.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchState" = 'MatchConfirmed'
        ) s ;

-- END  

$BODY$
--   LANGUAGE plpgsql VOLATILE
	LANGUAGE sql stable
  COST 100;
ALTER FUNCTION carpoolvote.driver_confirmed_matches(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirmed_matches(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirmed_matches(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirmed_matches(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.driver_confirmed_matches(character varying, character varying) TO carpool_role;

-- Function: carpoolvote.rider_confirmed_match(character varying, character varying)

-- DROP FUNCTION carpoolvote.rider_confirmed_match(character varying, character varying);

CREATE OR REPLACE FUNCTION carpoolvote.rider_confirmed_match(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS json AS
$BODY$

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
            AND "matchState" = 'MatchConfirmed';
            -- AND "matchState" = 'Canceled';

       RETURN row_to_json(r_row);

END  

$BODY$
   LANGUAGE plpgsql VOLATILE
	-- LANGUAGE sql stable
  COST 100;
ALTER FUNCTION carpoolvote.rider_confirmed_match(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_confirmed_match(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_confirmed_match(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_confirmed_match(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.rider_confirmed_match(character varying, character varying) TO carpool_role;

