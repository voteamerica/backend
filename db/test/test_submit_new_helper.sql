DO
$$
DECLARE
 v_uuid character varying(50):= '';
 v_error_code integer := 0;
 v_error_text text := '';
BEGIN

SELECT * from carpoolvote.submit_new_helper (
'David',
'david.milet@gmail.com',
'{"driving", "cooking"}' 
)
into v_uuid, v_error_code,v_error_text;

IF v_error_code != 0
THEN
	RAISE NOTICE '%', 'Error Code=' || v_error_code || ': ' || v_error_text;  
ELSE
	RAISE NOTICE '%', 'Successfully submitted uuid=' || v_uuid;
END IF;

END
$$

