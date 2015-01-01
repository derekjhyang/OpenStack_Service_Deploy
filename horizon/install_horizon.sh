#!/usr/bin/env bash

apt-get install -y openstack-dashboard apache2 libapache2-mod-wsgi memcached python-memcache

service apache2 restart
service memcached restart
