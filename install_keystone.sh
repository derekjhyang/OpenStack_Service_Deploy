#!/usr/bin/env bash
# author: Winnie Yang

# enable trace
set -x 

DATABASE_HOST=localhost
DATABASE_USER=root
DATABASE_PASSWORD=root
KEYSTONE_USER=keystone
KEYSTONE_PW=keystone
KEYSTONE_CONFIG_PATH=/etc/keystone/keystone.conf

mysql -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASSWORD} \
      -e "DROP DATABASE IF EXISTS keystone;"\
"CREATE DATABASE keystone;"\
"GRANT ALL PRIVILEGES ON keystone.* TO '${KEYSTONE_USER}'@'localhost' IDENTIFIED BY '${KEYSTONE_PW}';"\
"GRANT ALL PRIVILEGES ON keystone.* TO '${KEYSTONE_USER}'@'%' IDENTIFIED BY '${KEYSTONE_PW}';"

apt-get install -y keystone python-keystoneclient


# ======================
# Update Identity Config
# ======================
# generate admin token
ADMIN_TOKEN=$(openssl rand -hex $((${RANDOM}/100)))
if [ -f ${KEYSTONE_CONFIG_PATH} ];then
    sed -i -r "s|^(#? *)(admin_token)( *= *)(.*)|admin_token = ${ADMIN_TOKEN}|g" ${KEYSTONE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(connection)( *= *)(.*)|connection = mysql://${KEYSTONE_USER}:${KEYSTONE_PW}@${DATABASE_HOST}/keystone|g" ${KEYSTONE_CONFIG_PATH}

    # update UUID Provider and driver
    PROVIDER=keystone.token.providers.uuid.Provider
    DRIVER=keystone.token.persistence.backend.sql.Token
    sed -i -r "s/^(#? *)(provider)( *= *)(.*)/provider = ${PROVIDER}/g" ${KEYSTONE_CONFIG_PATH}
    sed -i -r "s/^(#? *)(driver)( *= *)(.*)/driver = ${DRIVER}/g" ${KEYSTONE_CONFIG_PATH}

fi


# sync the 'keystone' database
keystone-manage db_sync

# restart keystone
service keystone restart
