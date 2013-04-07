#!/usr/bin/env bash
# author: Winnie Yang
# [Description]
#    deploy SAMEVEDv2 Identity Services
#

# enable trace
set -x 

#================================#
# Import SAMEVED Identity Config #
#================================#
SAMEVED_IDENTITY_CONFIG=sameved_identity_config
if [ ! -e ${SAMEVED_IDENTITY_CONFIG} ];then
    echo "ERROR: can't find '${SAMEVED_IDENTITY_CONFIG}'"
    exit 1
fi
source ${SAMEVED_IDENTITY_CONFIG}


#========================#
# Update Identity Config #
#========================#

# generate keystone token
KEYSTONE_TOKEN=$(openssl rand -hex 40)

# update keystone token into 'SAMEVED Identity Config'
sed -i -r "s/^(KEYSTONE_TOKEN=)(.*)/\1${KEYSTONE_TOKEN}/g" ${SAMEVED_IDENTITY_CONFIG}

# export to '.bashrc' 
USER=$(whoami)
if [ $USER == 'root' ];then
    config_file=/root/.bashrc
else
    config_file=/home/${USER}/.bashrc
fi

# first clean up all the previous settings
sed -i '/^export\ OS/d' ${config_file}
sed -i '/^export\ AUTH/d' ${config_file}

# then export sys config to '.bashrc'
echo "export OS_USERNAME=${ADMIN}" >> ${config_file} 
echo "export OS_PASSWORD=${ADMIN_PASSWORD}" >> ${config_file} 
echo "export OS_TENANT_NAME=${ADMIN_TENANT}" >> ${config_file} 
echo "export OS_AUTH_URL=${KEYSTONE_PUBLIC_URL}" >> ${config_file} 
echo "export AUTH_TOKEN=${KEYSTONE_TOKEN}" >> ${config_file}

# update token in the '/etc/keystone/keystone.conf'
KEYSTONE_CONF=/etc/keystone/keystone.conf
if [ -f ${KEYSTONE_CONF} ];then
    sed -i -r "s/^(admin_token)( *= *)(.*)/\1 = ${KEYSTONE_TOKEN}/g" ${KEYSTONE_CONF}
fi


#=========================================#
# renew the keystone database and sync it #
#=========================================#
mysql -h ${DATABASE_HOST} \
      -u ${DATABASE_USER} \
      -p${DATABASE_PASSWORD} \
      -e "drop database if exists ${DATABASE};  
          create database ${DATABASE};
          exit" 2>&1 > /dev/null 
          
# sync the 'keystone' database
keystone-manage db_sync

# restart keystone
service keystone restart

# wait for keystone ready
sleep 5

# create sameved services
bash create-sameved-services.sh

# create sameved service endpoints
bash create-sameved-service-endpoints.sh

# restart 'keystone' service
service keystone restart
keystone-manage db_sync
