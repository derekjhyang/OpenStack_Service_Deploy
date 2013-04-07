#!/usr/bin/env bash
# author: Winnie Yang
#
#

#mysql_host=localhost
mysql_host=$(ifconfig eth0 | grep 'inet addr' | cut -d':' -f2 | sed 's/ .*//')
mysql_admin=
mysql_pw=


#
# create keystone
#
mysql -u${mysql_admin} -p${mysql_pw} -e "drop database if exists keystone"
mysql -u${mysql_admin} -p${mysql_pw} -e "delete from mysql.user where user='keystone'"
mysql -u${mysql_admin} -p${mysql_pw} -e "create database keystone"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on keystone.* to 'keystone'@localhost identified by '${mysql_pw}'"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on keystone.* to 'keystone'@'${mysql_host}' identified by '${mysql_pw}'"

#
# create glance
#
mysql -u${mysql_admin} -p${mysql_pw} -e "drop database if exists glance"
mysql -u${mysql_admin} -p${mysql_pw} -e "delete from mysql.user where user='glance'"
mysql -u${mysql_admin} -p${mysql_pw} -e "create database glance"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on glance.* to 'glance'@localhost identified by '${mysql_pw}'"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on glance.* to 'glance'@'${mysql_host}' identified by '${mysql_pw}'"


#
# create cinder
#
mysql -u${mysql_admin} -p${mysql_pw} -e "drop database if exists cinder"
mysql -u${mysql_admin} -p${mysql_pw} -e "delete from mysql.user where user='cinder'"
mysql -u${mysql_admin} -p${mysql_pw} -e "create database cinder"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on cinder.* to 'cinder'@localhost identified by '${mysql_pw}'"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on cinder.* to 'cinder'@'${mysql_host}' identified by '${mysql_pw}'"


#
# create nova
#
mysql -u${mysql_admin} -p${mysql_pw} -e "drop database if exists nova"
mysql -u${mysql_admin} -p${mysql_pw} -e "delete from mysql.user where user='nova'"
mysql -u${mysql_admin} -p${mysql_pw} -e "create database nova"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on nova.* to 'nova'@localhost identified by '${mysql_pw}'"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on nova.* to 'nova'@'${mysql_host}' identified by '${mysql_pw}'"

#
# create quantum
#
mysql -u${mysql_admin} -p${mysql_pw} -e "drop database if exists quantum"
mysql -u${mysql_admin} -p${mysql_pw} -e "delete from mysql.user where user='quantum'"
mysql -u${mysql_admin} -p${mysql_pw} -e "create database quantum"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on quantum.* to 'quantum'@localhost identified by '${mysql_pw}'"
mysql -u${mysql_admin} -p${mysql_pw} -e "grant all privileges on quantum.* to 'quantum'@'${mysql_host}' identified by '${mysql_pw}'"
