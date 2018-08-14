# To create VM in VirtualBox
vagrant up --provider virtualbox carpool-vb

The VM is created, started and provisioned.
Containers are not started.

vagrant ssh carpool-vb

sudo su - 

cd /opt/carpool/backend
docker-compose -f docker-compose.yml up


[root@localhost ~]# docker ps
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                          NAMES
1e783d70be25        carpool/nginx           "nginx -g 'daemon ..."   3 minutes ago       Up 3 minutes        80/tcp, 0.0.0.0:443->443/tcp   cp_nginx
5882a197b93e        carpool/api             "npm start"              3 minutes ago       Up 3 minutes        3030/tcp                       cp_api
94a02fdad57d        carpool/sms_handler     "npm start"              3 minutes ago       Up 3 minutes                                       cp_sms_handler
d4a272b2d1e0        carpool/matching        "npm start"              3 minutes ago       Up 3 minutes                                       cp_matching
45e6574c9965        carpool/email_handler   "python -u ./email..."   3 minutes ago       Up 3 minutes                                       cp_emailer
170e9f6c23cc        adminer                 "entrypoint.sh doc..."   3 minutes ago       Up 3 minutes        127.0.0.1:8080->8080/tcp       cp_adminer
8df808cd434e        carpool/pg_server       "docker-entrypoint..."   3 minutes ago       Up 3 minutes        5432/tcp                       cp_pg_server


You can verify that the API server is running with
curl -k https://localhost:443/live/unmatched-drivers
(should return [] , no unmatched drivers, or a list of unmatches drivers)


This VirtualBox VM comes with a Host-Only network interface, through which the API server running on port 443 is reachable too. 
So, to connect the front-end to it, just define in your /etc/hosts file 
<ip of the VM's host-only interface> api.carpoolvote.com




