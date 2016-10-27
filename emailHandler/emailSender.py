#!/usr/bin/python3.5
import sys
import requests
import psycopg2


########################################################
# must pass db name as first argument
########################################################


key = 'key-288a0fac896a89f91855c2e3a8d2bac6'
request_url = 'https://api.mailgun.net/v3/www.carpoolvote.com/messages'

try:
	conn = psycopg2.connect("dbname={0} user='carpool_match_engine' host='/tmp'".format(sys.argv[1]))
except:
	print ("I am unable to connect to the database")
	exit

cur = conn.cursor()
cur.execute("""SELECT id, recipient, subject, body from nov2016.outgoing_email where state='Pending' order by created_ts asc """)

rows = cur.fetchall()

for row in rows:
	print (row[1] + ' ' + row[2] + '\n' + row[3] + '\n')
	
	request = requests.post(request_url, auth=('api', key), data={
		'from': 'noreply@carpoolvote.com',
		'to': row[1],
		'subject': row[2],
		'html': row[3]
		})
	
	print ('Status: {0}'.format(request.status_code))
	print ('Body:   {0}'.format(request.text))

	if request.status_code == 200:
		cur.execute("""UPDATE nov2016.outgoing_email
						SET state='Sent', emission_info = '200 - OK' 
						WHERE id = %s""", (row[0],))
	else:
		cur.execute("""UPDATE nov2016.outgoing_email
						SET state='Failed', emission_info = %s 
						WHERE id = %s""", ("{0}: {1}".format(request.status_code,request.text), "{0}".format(row[0]), ))

	conn.commit()
	
cur.close()
conn.close()


