pg_dump -d carpool_v2.0_live -f carpool_static_data.dat -F c -Z 9 -a -n nov2016 -t nov2016.bordering_state -t nov2016.tz_dst_offset -t nov2016.usstate -t nov2016.zip_codes
