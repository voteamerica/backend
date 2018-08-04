FROM nginx
COPY ./conf/cp_nginx_docker.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /etc/letsencrypt/live/api.carpoolvote.com

# We install default, self-signed certificate here
# When docker-compose is run, the letsencrypt folder will be mounted as a volume 
# so a proper letsencrypt certificate can be installed
# For DEV environments, a self-signed cert will suffice
COPY ./self-signed-cert/nginx-selfsigned-cert.pem /etc/letsencrypt/live/api.carpoolvote.com/fullchain.pem
COPY ./self-signed-cert/nginx-selfsigned-key.pem  /etc/letsencrypt/live/api.carpoolvote.com/privkey.pem

