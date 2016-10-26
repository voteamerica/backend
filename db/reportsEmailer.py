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
cur.execute("""SELECT value from nov2016.params where name='reports_mailing_list'""")

rows = cur.fetchall()

for row in rows:
	recipients = row[0].split(',')

	#print (recipients)
	body = "".join(sys.stdin)	
	#print ('\n')
	#print (body)
	request = requests.post(request_url, auth=('api', key), data={
		'from': 'noreply@carpoolvote.com',
		'to': recipients,
		'subject': "{0}".format(sys.argv[2]) ,
		'text': body 
		})
	
	print ('Status: {0}'.format(request.status_code))
#	print ('Body:   {0}'.format(request.text))
cur.close()
conn.close()


