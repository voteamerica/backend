#!/usr/bin/sh


if [ $(egrep -c "^local.*all.*carpool_app,carpool_web,carpool_admin.*trust" /var/lib/pgsql/9.6/data/pg_hba.conf) -lt 1 ]; then
echo "adding trust permission for carpool users"
cp -p /var/lib/pgsql/9.6/data/pg_hba.conf /var/lib/pgsql/9.6/data/pg_hba.conf.orig
cp -p /var/lib/pgsql/9.6/data/pg_hba.conf /var/lib/pgsql/9.6/data/pg_hba.conf.new
> /var/lib/pgsql/9.6/data/pg_hba.conf.new


while read line
do
if [[ $line =~ ^local.*all.*all.*peer ]]; then
    echo "local   all             carpool_app,carpool_web,carpool_admin   trust" >> /var/lib/pgsql/9.6/data/pg_hba.conf.new
fi
echo "$line" >>  /var/lib/pgsql/9.6/data/pg_hba.conf.new

done < /var/lib/pgsql/9.6/data/pg_hba.conf.orig

cp /var/lib/pgsql/9.6/data/pg_hba.conf.new /var/lib/pgsql/9.6/data/pg_hba.conf

fi

