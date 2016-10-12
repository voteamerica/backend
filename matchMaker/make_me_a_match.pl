#!/usr/bin/perl
use DBI;

$db_hostname = "api.carpoolvote.com";  # api.carpoolvote.com
$db_name = "carpool";
$db_user = "eric";
$db_password = "eric1234567890";
$connection_string = "dbi:Pg:dbname=".$db_name.";host=".$db_hostname.";port=5432;"; 

my $dbh = DBI->connect($connection_string, $db_user, $db_password,{AutoCommit=>1,RaiseError=>1,PrintError=>0});
#'dbi:Pg:dbname=carpool;host='+$db_hostname+';port=5432;'
#,'eric','eric1234567890'

# ------------------------------------------------------------------------------------
# Select any records from the database which are in need of a match. 
# ------------------------------------------------------------------------------------
while (true) {
   # ------------------------------------------------------------------------------------
   # Pickup the first such record, based on order of insertion. 
   # ------------------------------------------------------------------------------------
   # (FIFO)
   #  
   # Determine if we have any drivers who could provide that ride, 
   # based on :
   print "Picking up oldest Ride Request which has not been processed.\n";
   # Starting ZIP Code
   # Assume return duration (30 Minutes)
   #
   # Is driver "going that way", (one-way ride)
   # or is driver "helping by driving" (providing multiple rides)
   # 
   # Does rider have any special needs (ability for driver to load a power chair, for example) which the driver can satisfy?
   #

 	$SQL = 'SELECT "rider"."RiderID" ';
 	$SQL.= ', "requested_ride"."OriginZIP" ';
 	$SQL .= '      FROM "nov2016"."rider" ';
 	$SQL .= ' INNER JOIN "nov2016"."requested_ride" ';
 	$SQL .= '         ON "rider"."RiderID" = "requested_ride"."RiderID" ';
# $SQL .=' INNER JOIN "nov2016"."status" on "requested_ride".

 $SQL .=' LIMIT 1 ';

 $rider_zip_code = "";
 print "RIDER TO MATCH:", $dbh->selectrow_array($SQL), "\n";
 
 @myary = $dbh->selectrow_array($SQL);
 print @myary[0];
 if ( $rider_zip_code != "") {
	 $rider_zip_code = "85254"; # Sanitize to 5 numbers.

	 $DRIVER_SQL = 'SELECT * ';
	 $DRIVER_SQL.= '  FROM "nov2016"."driver" AS DRIVER ';
	 $DRIVER_SQL.= ' INNER JOIN "nov2016"."zip_codes" ZIPS ON DRIVER. = ZIPS.ZIP_CODE ';
	 $DRIVER_SQL.= ' WHERE ZIPS.ZIP_CODE = '+ $rider_zip_code +';';

	 print "SQL HERE:\n";
	 print "---------------\n";
 	 print($SQL);
	 print "---------------\n";

 }

 # ------------------------------------------------------------------------------------
 # For each of the potential drivers, add a Proposed Match record into the database.
 # ------------------------------------------------------------------------------------
 # ------------------------------------------------------------------------------------
 # Loop Around to See if there Are additional Riders who need to be matched.
 #
 # ------------------------------------------------------------------------------------
 print "Looping for more items.";
 sleep 5; # Seconds
}

