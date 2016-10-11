    -- // get uuid and last Name
    -- // from uuid, get timestamp then riderId from statusRider
    -- // execute nov2016 cancel_ride_by_rider 

CREATE FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) 
  RETURNS integer AS $$
DECLARE
    retVal integer := -1;
    riderID integer := -1; 
BEGIN
    -- RAISE NOTICE 'retVal here is %', retVal; 

    -- get timestamp of unprocessed riders 
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
      -- select MAX("CreatedTimeStamp") into tstamp from stage.status_rider;
      SELECT stage.status_rider."RiderID" 
      INTO 
        riderID
      FROM stage.status_rider  
        INNER JOIN 
          stage.websubmission_rider 
        ON 
          (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
      WHERE 
        stage.websubmission_rider."UUID" = "rider_UUID";

      retVal := 2;      
    ELSE 
      RETURN retVal;
    END IF;

    -- RAISE NOTICE 'riderID here is %', riderID; 

    SELECT nov2016.cancel_ride_by_rider(riderID) INTO retVal;
    
    RETURN retVal;
END;
$$ LANGUAGE plpgsql;

GRANT ALL ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_admins;
GRANT EXECUTE ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_role;

-- select stage.cancel_ride('2fbbd358-c1e8-45fc-bd00-3bf3fd3d7c64')
  --      "rider_UUID";
