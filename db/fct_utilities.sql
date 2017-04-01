SET search_path = carpoolvote, pg_catalog;

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
GRANT EXECUTE ON FUNCTION  carpoolvote.urlencode(text, out text) TO carpool_role;
GRANT EXECUTE ON FUNCTION  carpoolvote.urlencode(text, out text) TO carpool_web_role;



CREATE OR REPLACE FUNCTION carpoolvote.get_param_value(a_param_name character varying)
  RETURNS character varying AS
$BODY$
DECLARE

v_env carpoolvote.params.value%TYPE;

BEGIN

v_env := NULL;

BEGIN
	SELECT value INTO v_env FROM carpoolvote.params WHERE name=a_param_name;
EXCEPTION WHEN OTHERS
THEN
	v_env := NULL;
END;

RETURN v_env;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION carpoolvote.get_param_value(character varying)
  OWNER TO carpool_admins;
GRANT EXECUTE ON FUNCTION carpoolvote.get_param_value(character varying) TO carpool_web;
GRANT EXECUTE ON FUNCTION carpoolvote.get_param_value(character varying) TO carpool_role;



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
GRANT ALL ON FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO PUBLIC;
GRANT ALL ON FUNCTION carpoolvote.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) TO carpool_role;
