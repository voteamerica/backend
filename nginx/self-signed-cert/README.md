NOTE : TO BE USED ONLY FOR DEV/TEST PURPOSES
FOR LIVE OPERATIONS MAKE SURE A PROPER CERTIFICATE FROM LETS ENCRYPT IS USED

Reference : 
https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-centos-7

Command to re-create the self-signed cert (valid for 10 years)
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout nginx-selfsigned-key.pem -out nginx-selfsigned-cert.pem -subj "/C=US/CN=api.carpoolvote.com"


