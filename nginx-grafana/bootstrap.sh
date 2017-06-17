#!/bin/bash

# Setting selinux to permissive for now, will fix after I change the httpd docroot
setenforce permissive

# Installing pre-reqs for graphite
yum -y install epel-release
#yum -y install httpd
#yum -y install mod_wsgi
yum -y install python-pip
yum -y install python-devel
yum -y install python-ldap
yum -y install python-flup
yum -y install expect
yum -y install memcached
yum -y install gcc
yum -y install cairo-devel 
yum -y install libffi-devel
yum -y install iptables-services
 
# Installing python pre-reqs
export PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/"
pip install --upgrade pip
pip install django==1.5.12
pip install python-memcached==1.53
pip install django-tagging==0.3.1
pip install twisted==11.1.0
pip install txAMQP==0.6.2
pip install pytz
pip install cairocffi
#pip install whitenoise

# Installing graphite components
pip install whisper==0.9.15
pip install carbon==0.9.15
pip install graphite-web==0.9.15

# Putting necessary conf files into place (See Vagrantfile)
mv /tmp/graphite-files/opt/graphite/conf/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
mv /tmp/graphite-files/opt/graphite/conf/storage-aggregation.conf /opt/graphite/conf/storage-aggregation.conf
mv /tmp/graphite-files/opt/graphite/conf/graphTemplates.conf /opt/graphite/conf/graphTemplates.conf
mv /tmp/graphite-files/opt/graphite/conf/graphite.wsgi /opt/graphite/conf/graphite.wsgi
mv /tmp/graphite-files/opt/graphite/conf/carbon.conf /opt/graphite/conf/carbon.conf
mv /tmp/graphite-files/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
#mv /tmp/graphite-files/etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf
#mv /tmp/graphite-files/etc/httpd/conf.d/graphite.conf /etc/httpd/conf.d/graphite.conf

# Startup the carbon daemon
python /opt/graphite/bin/carbon-cache.py start

# Init Django DB
python /opt/graphite/webapp/graphite/manage.py syncdb --noinput
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@admin.com', 'password')" | python /opt/graphite/webapp/graphite/manage.py shell

# Creating requisite log directories
mkdir -p /var/log/graphite/webapp
touch /var/log/graphite/webapp/error.log
touch /var/log/graphite/webapp/access.log

mkdir -p /var/log/graphite/storage
touch /var/log/graphite/storage/info.log
touch /var/log/graphite/storage/exception.log

# Fix log permissions
#chown -R apache:apache /var/log/graphite

#Changing httpd permissions to make sure apache can access them
#chown -R apache:apache /etc/httpd
#$chmod -R 755 /etc/httpd

# Changing graphite permissions to let apache access them
#chown -R apache:apache /opt/graphite
chmod -R 755 /opt/graphite

# Setting up iptables rules for http
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
service iptables save

# This needs run because of weirdness with syncdb --noinput and the httpd server
# Reference: https://github.com/gdbtek/setup-graphite/issues/2
P=`dd if=/dev/urandom bs=1 count=64 2>/dev/null | tr -dc _A-Z-a-z-0-9` \
echo "from django.contrib.auth.models import User; User.objects.create_user('default','default@localhost.localdomain','$P')" \ |sudo -u apache python /opt/graphite/webapp/graphite/manage.py shell

# Starting the apache service
# For some reason starting the service the first time is locking the DB
#systemctl start httpd

# Installing grafana via yum
#yum -y install https://grafanarel.s3.amazonaws.com/builds/grafana-4.1.1-1484211277.x86_64.rpm
#mv /tmp/graphite-files/etc/grafana/grafana.ini /etc/grafana/grafana.ini
