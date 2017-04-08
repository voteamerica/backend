pg_dump -d carpool_v2.0_live -f carpool_static_data.dat -F c -Z 9 -a -n carpoolvote -t carpoolvote.bordering_state -t carpoolvote.tz_dst_offset -t carpoolvote.usstate -t carpoolvote.zip_codes
