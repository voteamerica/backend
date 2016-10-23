/* CREATE TABLE */

/*

create table nov2016.tz_dst_offset (
 timezone 		text 					primary key
,observes_dst   character varying(50)
,offset_summer 	integer
,offset_fall 	integer
);

*/

/*
           timezone				|	ObservesDST	|LTNov6	| GTNov6 |	Notes
--------------------------------|--------------------------------------------------------------------
 America/Puerto_Rico			|	NO			|UTC-04 | UTC-04 |	NO DST ---
 America/New_York				|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Indiana/Vincennes		|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Indiana/Marengo		|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Indiana/Winamac		|	YES			|UTC-04	| UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Kentucky/Louisville	|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Indiana/Petersburg		|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Indiana/Vevay			|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Indiana/Indianapolis	|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Kentucky/Monticello	|	YES			|UTC-04 | UTC-05 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour

 America/Indiana/Knox			|	YES			|UTC-05 | UTC-06 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Detroit				|	YES			|UTC-05	| UTC-06 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Chicago				|	YES			|UTC-05 | UTC-06 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/North_Dakota/Center	|	YES			|UTC-05 | UTC-06 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Indiana/Tell_City		|	YES			|UTC-05 | UTC-06 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Menominee				| 	YES			|UTC-05 | UTC-06 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour

 America/Boise					|	YES			|UTC-06 | UTC-07 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour	 
 America/Shiprock				|	YES			|UTC-06 | UTC-07 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour	 
 America/Denver					|	YES			|UTC-06 | UTC-07 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour 

 America/Phoenix				|	NO 			|UTC-07 | UTC-07 |	NO DST ---
 America/Los_Angeles			|	YES			|UTC-07	| UTC-08 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour

 America/Juneau					|	YES			|UTC-08	| UTC-09 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Yakutat				|	YES			|UTC-08	| UTC-09 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Nome					|	YES			|UTC-08	| UTC-09 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour
 America/Anchorage				|	YES			|UTC-08	| UTC-09 |	DST ends Sun 6-Nov-2016 at 02:00:00 A.M.; set backward 1 hour

 Pacific/Honolulu				|	NO 			|UTC-10	| UTC-10 |  NO DST ---
--------------------------------|--------------------------------------------------------------------

*/

--  timezone | observes_dst | offset_summer | offset_fall
-- ----------+--------------+---------------+-------------

INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Puerto_Rico'				,false 	, -4	,-4	    );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/New_York'				,true	, -4	,-5		);	
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Vincennes'		,true	, -4	,-5	    );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Marengo'			,true	, -4	,-5	    );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Winamac'			,true	, -4	,-5	    );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Kentucky/Louisville'		,true	, -4	,-5     );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Petersburg'		,true	, -4	,-5	    );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Vevay'			,true	, -4	,-5		);
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Indianapolis'	,true	, -4	,-5     );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Kentucky/Monticello'		,true	, -4	,-5     );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Knox'			,true	, -5	,-6		);
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Detroit'					,true	, -5	,-6		);	
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Chicago'					,true	, -5	,-6		);	
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/North_Dakota/Center'		,true	, -5	,-6     );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Indiana/Tell_City'		,true	, -5	,-6	    );
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Menominee'				,true	, -5	,-6		);	
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Boise'					,true	, -6	,-7		);		
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Shiprock'				,true	, -6	,-7		);	
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Denver'					,true	, -6	,-7		);		
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Phoenix'					,false	, -7	,-7		);	
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Los_Angeles'				,true	, -7	,-8		);	
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Juneau'					,true	, -8	,-9		);			
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Yakutat'					,true	, -8	,-9		);		
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Nome'					,true	, -8	,-9		);				
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'America/Anchorage'				,true	, -8	,-9		);		
INSERT INTO  nov2016.tz_dst_offset ( timezone , observes_dst , offset_summer , offset_fall ) VALUES ( 'Pacific/Honolulu'				,false	, -10	,-10	);

/*

carpool_v2.0_live=# SELECT * FROM NOV2016.tz_dst_offset;
           timezone           | observes_dst | offset_summer | offset_fall
------------------------------+--------------+---------------+-------------
 America/Puerto_Rico          | false        |            -4 |          -4
 America/New_York             | true         |            -4 |          -5
 America/Indiana/Vincennes    | true         |            -4 |          -5
 America/Indiana/Marengo      | true         |            -4 |          -5
 America/Indiana/Winamac      | true         |            -4 |          -5
 America/Kentucky/Louisville  | true         |            -4 |          -5
 America/Indiana/Petersburg   | true         |            -4 |          -5
 America/Indiana/Vevay        | true         |            -4 |          -5
 America/Indiana/Indianapolis | true         |            -4 |          -5
 America/Kentucky/Monticello  | true         |            -4 |          -5
 America/Indiana/Knox         | true         |            -5 |          -6
 America/Detroit              | true         |            -5 |          -6
 America/Chicago              | true         |            -5 |          -6
 America/North_Dakota/Center  | true         |            -5 |          -6
 America/Indiana/Tell_City    | true         |            -5 |          -6
 America/Menominee            | true         |            -5 |          -6
 America/Boise                | true         |            -6 |          -7
 America/Shiprock             | true         |            -6 |          -7
 America/Denver               | true         |            -6 |          -7
 America/Phoenix              | false        |            -7 |          -7
 America/Los_Angeles          | true         |            -7 |          -8
 America/Juneau               | true         |            -8 |          -9
 America/Yakutat              | true         |            -8 |          -9
 America/Nome                 | true         |            -8 |          -9
 America/Anchorage            | true         |            -8 |          -9
 Pacific/Honolulu             | false        |           -10 |         -10
(26 rows)

*/
