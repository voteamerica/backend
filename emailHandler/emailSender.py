#!/usr/bin/python
import os
import sys
import requests
import psycopg2
import time
import datetime

########################################################
# requires the following environment variables
# MAILGUNKEY : the mailgun key
# PGDATABASE : the name of the database
########################################################

request_url = 'https://api.mailgun.net/v3/www.carpoolvote.com/messages'
key = os.environ['MAILGUNKEY']
sleep_secs = os.getenv('CP_DELAY', 10000)/1000

while True:
	time.sleep(sleep_secs)

	try:
		conn = psycopg2.connect("dbname={0}".format(os.environ['PGDATABASE']), host='cp_pg_server', user='carpool_app')
	except psycopg2.Error as e:
		print ("Unable to connect to the database: {0}".format(e.pgerror))
		continue

	cur = conn.cursor()
	cur.execute("""SELECT id, recipient, subject, body from carpoolvote.outgoing_email where status='Pending' order by created_ts asc """)

	rows = cur.fetchall()
	print (datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") + ' Emails to send: {0}'.format(len(rows)))
	for row in rows:
		#print (row[1] + ' ' + row[2] + '\n' + row[3] + '\n')

		request = requests.post(request_url, auth=('api', key), data={
			'from': 'Carpool Vote <noreply@carpoolvote.com>',
			'to': row[1],
			'subject': row[2],
			'html': row[3]
			})

		print ('Status: {0}'.format(request.status_code))
		print ('Body:   {0}'.format(request.text))

		if request.status_code == 200:
			cur.execute("""UPDATE carpoolvote.outgoing_email
							SET status='Sent', emission_info = '200 - OK'
							WHERE id = %s""", (row[0],))
		else:
			cur.execute("""UPDATE carpoolvote.outgoing_email
							SET status='Failed', emission_info = %s
							WHERE id = %s""", ("{0}: {1}".format(request.status_code,request.text), "{0}".format(row[0]), ))

		conn.commit()

	cur.close()
	conn.close()
