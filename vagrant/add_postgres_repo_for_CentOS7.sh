#!/usr/bin/sh


cd /tmp
wget https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
rpm -i --force pgdg-centos96-9.6-3.noarch.rpm

if [ $(grep -c "exclude=postgresql" /etc/yum.repos.d/CentOS-Base.repo) -lt 2 ]; then
echo "adding postgres excludes"
cp -p /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.orig
cp -p /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.new
> /etc/yum.repos.d/CentOS-Base.repo.new

while read line
do
echo $line >>  /etc/yum.repos.d/CentOS-Base.repo.new
if [[ $line == "[base]" ]]; then
    echo "exclude=postgresql*" >> /etc/yum.repos.d/CentOS-Base.repo.new
else
    if [[ $line == "[updates]" ]]; then
        echo "exclude=postgresql*" >> /etc/yum.repos.d/CentOS-Base.repo.new
    fi
fi

done < /etc/yum.repos.d/CentOS-Base.repo.orig

cp /etc/yum.repos.d/CentOS-Base.repo.new /etc/yum.repos.d/CentOS-Base.repo

fi

cd -
