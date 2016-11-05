-- Function: nov2016.driver_exists(character varying, character varying)

-- DROP FUNCTION nov2016.driver_exists(character varying, character varying);

CREATE OR REPLACE FUNCTION nov2016.driver_exists(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.driver_exists(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_exists(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_exists(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION nov2016.driver_exists(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_exists(character varying, character varying) TO carpool_role;


-- Function: nov2016.rider_exists(character varying, character varying)

-- DROP FUNCTION nov2016.rider_exists(character varying, character varying);

CREATE OR REPLACE FUNCTION nov2016.rider_exists(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS character varying AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.rider_exists(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.rider_exists(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.rider_exists(character varying, character varying) TO carpool_role;
GRANT EXECUTE ON FUNCTION nov2016.rider_exists(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.rider_exists(character varying, character varying) TO public;


CREATE OR REPLACE FUNCTION nov2016.rider_info(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS json AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.rider_info(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.rider_info(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.rider_info(character varying, character varying) TO carpool_role;
GRANT EXECUTE ON FUNCTION nov2016.rider_info(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.rider_info(character varying, character varying) TO public;


-- Function: nov2016.driver_info(character varying, character varying)

-- DROP FUNCTION nov2016.driver_info(character varying, character varying);

CREATE OR REPLACE FUNCTION nov2016.driver_info(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS json AS
$BODY$

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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.driver_info(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_info(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_info(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION nov2016.driver_info(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_info(character varying, character varying) TO carpool_role;

DROP VIEW nov2016.vw_driver_matches;

CREATE VIEW nov2016.vw_driver_matches 
AS
    SELECT 
        nov2016.match."state" AS "matchState", 
    "uuid_driver", "uuid_rider", "score", "UUID", "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail", "RiderPhone", "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesUTC", "TotalPartySize", "TwoWayTripNeeded", "RiderIsVulnerable", "RiderWillNotTalkPolitics", "PleaseStayInTouch", "NeedWheelchair", "RiderPreferredContact", "RiderAccommodationNotes", "RiderLegalConsent", "ReadyToMatch", 
    stage.websubmission_rider."state", 
    "state_info", "RiderWillBeSafe", "AvailableRideTimesLocal", "RiderCollectionAddress", "RiderDestinationAddress"
 FROM nov2016.match
    INNER JOIN 
        stage.websubmission_rider on 
        stage.websubmission_rider."UUID" = nov2016.match.uuid_rider;


-- Function: nov2016.driver_proposed_matches(character varying, character varying)

-- DROP FUNCTION nov2016.driver_proposed_matches(character varying, character varying);

CREATE OR REPLACE FUNCTION nov2016.driver_proposed_matches(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS setof json AS
$BODY$

-- DECLARE                                                   
-- 	drive_offer_row stage.websubmission_driver%ROWTYPE;
-- 	v_step character varying(200); 
-- 	v_return_text character varying(200);	
-- 	d_row nov2016.vw_driver_matches%ROWTYPE;
--BEGIN 

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
    --     --RETURN row_to_json(null);
	-- END IF;

    --     SELECT * INTO
    --         d_row
    --     FROM
    --         nov2016.vw_driver_matches
    --     WHERE
    --             uuid_driver = a_uuid
    --         AND "matchState" = 'MatchProposed';

    --    RETURN row_to_json(d_row);


        select row_to_json(s)
        FROM ( 
            select * from
            nov2016.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchState" = 'MatchProposed'
        ) s ;

    --    RETURN row_to_json(d_row);



    --    RETURN row_to_json(
    --        --d_row
    --         SELECT match FROM nov2016.match
    --         INNER JOIN 
    --             stage.websubmission_rider on 
    --             stage.websubmission_rider."UUID" = nov2016.match.uuid_rider
    --         WHERE uuid_driver = 'b57afc47-d97c-4c36-a078-6e68a0e9ef21' 
    --         AND nov2016.match.state = 'MatchProposed'
    --    );
	
--END  

$BODY$
--   LANGUAGE plpgsql VOLATILE
    LANGUAGE sql stable
  COST 100;
ALTER FUNCTION nov2016.driver_proposed_matches(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_proposed_matches(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_proposed_matches(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION nov2016.driver_proposed_matches(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_proposed_matches(character varying, character varying) TO carpool_role;

-- Function: nov2016.driver_confirmed_matches(character varying, character varying)

-- DROP FUNCTION nov2016.driver_confirmed_matches(character varying, character varying);

CREATE OR REPLACE FUNCTION nov2016.driver_confirmed_matches(
    a_uuid character varying,
    confirmation_parameter character varying)
  RETURNS json AS
$BODY$

DECLARE                                                   
	drive_offer_row stage.websubmission_driver%ROWTYPE;
	v_step character varying(200); 
	v_return_text character varying(200);	
	d_row nov2016.vw_driver_matches%ROWTYPE;
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
            nov2016.vw_driver_matches
        WHERE
                uuid_driver = a_uuid
            AND "matchState" = 'MatchConfirmed';
            -- AND "matchState" = 'Canceled';

       RETURN row_to_json(d_row);

END  

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION nov2016.driver_confirmed_matches(character varying, character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirmed_matches(character varying, character varying) TO carpool_admins;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirmed_matches(character varying, character varying) TO public;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirmed_matches(character varying, character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION nov2016.driver_confirmed_matches(character varying, character varying) TO carpool_role;

