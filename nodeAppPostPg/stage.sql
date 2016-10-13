GRANT SELECT ON TABLE stage.status_rider TO carpool_web_role;
GRANT SELECT ON TABLE stage.websubmission_rider TO carpool_web_role;

GRANT USAGE ON SCHEMA nov2016 TO carpool_web_role;
GRANT EXECUTE ON FUNCTION nov2016.cancel_ride_by_rider("RiderID" integer, "RequestedRideID" integer) TO carpool_web_role;
GRANT ALL ON TABLE nov2016.requested_ride TO carpool_web_role;

CREATE FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) 
  RETURNS integer AS $$
DECLARE
    retVal integer := -1;
    riderID integer := -1; 
BEGIN
    -- RAISE NOTICE 'retVal here is %', retVal; 

    IF EXISTS (
      SELECT stage.websubmission_rider."UUID" 
      FROM stage.status_rider  
        INNER JOIN 
          stage.websubmission_rider 
        ON 
          (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
         
      WHERE 
        stage.websubmission_rider."UUID" = "rider_UUID"
    )
    THEN
      SELECT stage.status_rider."RiderID" 
      INTO 
        riderID
      FROM stage.status_rider  
        INNER JOIN 
          stage.websubmission_rider 
        ON 
          (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
      WHERE 
        stage.websubmission_rider."UUID" = $1;

      retVal := 2;      
    ELSE 
      RAISE EXCEPTION 'UUID not found %', $1; 
    END IF;


    SELECT nov2016.cancel_ride_by_rider(riderID) INTO retVal;
    
    RETURN retVal;
END;
$$ LANGUAGE plpgsql;
-- select stage.cancel_ride('2fbbd358-c1e8-45fc-bd00-3bf3fd3d7c64')

GRANT ALL ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_admins;
GRANT EXECUTE ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_role;


-- NOTE: somewhat of a placeholder function. It confirms uuid is valid, else throws an exception
--       If uuid is valid, returns 1
--       Also, if don't need to access nov2016, then don't need inner joins below
CREATE FUNCTION stage.reject_ride("rider_UUID" character varying(50)) 
  RETURNS integer AS $$
DECLARE
    retVal integer := -1;
    riderID integer := -1; 
BEGIN
    -- RAISE NOTICE 'retVal here is %', retVal; 

    IF EXISTS (
      SELECT stage.websubmission_rider."UUID" 
      FROM stage.status_rider  
        -- see note above
        INNER JOIN 
          stage.websubmission_rider 
        ON 
          (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
         
      WHERE 
        stage.websubmission_rider."UUID" = "rider_UUID"
    )
    THEN
      SELECT stage.status_rider."RiderID" 
      INTO 
        riderID
      FROM stage.status_rider  
        -- see note above
        INNER JOIN 
          stage.websubmission_rider 
        ON 
          (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
      WHERE 
        stage.websubmission_rider."UUID" = $1;

      retVal := 2;      
    ELSE 
      RAISE EXCEPTION 'UUID not found %', $1; 
    END IF;


    -- SELECT nov2016.cancel_ride_by_rider(riderID) INTO retVal;
    
    RETURN retVal;
END;
$$ LANGUAGE plpgsql;

GRANT ALL ON FUNCTION stage.reject_ride("rider_UUID" character varying(50)) TO carpool_admins;
GRANT EXECUTE ON FUNCTION stage.reject_ride("rider_UUID" character varying(50)) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION stage.reject_ride("rider_UUID" character varying(50)) TO carpool_role;

-- select stage.reject_ride('2fbbd358-c1e8-45fc-bd00-3bf3fd3d7c64')
