#!/usr/bin/env bash
#author: Derrick Yang

# enable trace
set -x 

DATABASE_HOST=localhost
DATABASE_USER=root
DATABASE_PASSWORD=root
DATABASE=glance

SERVICE_USER=glance
SERVICE_PASSWORD=glance
SERVICE_ROLE=admin
SERVICE_TENANT=service
SERVICE_PUBLIC_PORT=9292
SERVICE_INTERNAL_PORT=9292
SERVICE_ADMIN_PORT=9292
GLANCE_API_CONFIG_PATH=/etc/glance/glance-api.conf
GLANCE_REGISTRY_CONFIG_PATH=/etc/glance/glance-registry.conf

CONTROLLER_IP=localhost

ENDPOINT_PUBLIC_URL=http://${CONTROLLER_IP}:${SERVICE_PUBLIC_PORT}
ENDPOINT_INTERNAL_URL=http://${CONTROLLER_IP}:${SERVICE_INTERNAL_PORT}
ENDPOINT_ADMIN_URL=http://${CONTROLLER_IP}:${SERVICE_ADMIN_PORT}
ENDPOINT_REGION=RegionOne



# ===============
# Create database
# ===============
mysql -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASSWORD} \
      -e "DROP DATABASE IF EXISTS ${DATABASE};"\
"CREATE DATABASE ${DATABASE};"\
"GRANT ALL PRIVILEGES ON ${DATABASE}.* TO '${SERVICE_USER}'@'localhost' IDENTIFIED BY '${SERVICE_PASSWORD}';"\
"GRANT ALL PRIVILEGES ON ${DATABASE}.* TO '${SERVICE_USER}'@'%' IDENTIFIED BY '${SERVICE_PASSWORD}';"

# =========================
# export amdmin credentials
# =========================
source ~/admin-openrc.sh

# a. Create the glance user.
USER_ID=$(keystone user-list | awk '/'${SERVICE_USER}'/{print $2}')
if [ ! -z ${USER_ID} ];then
    keystone user-delete ${USER_ID}
fi
keystone user-create --name ${SERVICE_USER} --pass ${SERVICE_PASSWORD}
# b. Link the glance user to the service tenant and admin role.
keystone user-role-add --user ${SERVICE_USER} --tenant ${SERVICE_TENANT} --role ${SERVICE_ROLE}
# c. Create the glance service.
SERVICE_ID=$(keystone service-list | awk '/image/{print $2}')
if [ ! -z ${SERVICE_ID} ];then
    keystone service-delete ${SERVICE_ID}
fi
keystone service-create --name ${SERVICE_USER} --type image --description "OpenStack Image Service"
# d. Create the service API endpoints.
keystone endpoint-create \
--service-id $(keystone service-list | awk '/image/{print $2}') \
--publicurl ${ENDPOINT_PUBLIC_URL} \
--internalurl ${ENDPOINT_INTERNAL_URL} \
--adminurl ${ENDPOINT_ADMIN_URL} \
--region ${ENDPOINT_REGION}

# ================
# Install Packages
# ================
apt-get install -y glance python-glanceclient

# ====================================
# Edit the /etc/glance/glance-api.conf
# ====================================
if [ -f ${GLANCE_API_CONFIG_PATH} ];then
    cp ${GLANCE_API_CONFIG_PATH} ${GLANCE_API_CONFIG_PATH}.sample
    # edit database access
    sed -i -r "s|^(#? *)(connection)( *= *)(.*)|connection = mysql://${SERVICE_USER}:${SERVICE_PASSWORD}@${DATABASE_HOST}/${DATABASE}" ${GLANCE_API_CONFIG_PATH}
    # edit the [keystone_authtoken] section
    sed -i -r "s|^(#? *)(auth_uri)( *= *)(.*)|auth_uri = http://${CONTROLLER_IP}:5000/v2.0" ${GLANCE_API_CONFIG_PATH}
    sed -i -r "s|^(#? *)(identity_uri)( *= *)(.*)|identity_uri = http://${CONTROLLER_IP}:35357" ${GLANCE_API_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_tenant_name)( *= *)(.*)|admin_tenant_name = ${SERVICE_TENANT}" ${GLANCE_API_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_user)( *= *)(.*)|admin_user = ${SERVICE_USER}" ${GLANCE_API_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_password)( *= *)(.*)|admin_password = ${SERVICE_PASSWORD}" ${GLANCE_API_CONFIG_PATH}
    # edit [paste_deploy] section 
    sed -i -r "s|^(#? *)(flavor)( *= *)(.*)|flavor = keystone" ${GLANCE_API_CONFIG_PATH}
fi


# =========================================
# Edit the /etc/glance/glance-registry.conf
# =========================================
if [ -f ${GLANCE_REGISTRY_CONFIG_PATH} ];then
    cp ${GLANCE_REGISTRY_CONFIG_PATH} ${GLANCE_REGISTRY_CONFIG_PATH}.sample
    # edit database access
    sed -i -r "s|^(#? *)(connection)( *= *)(.*)|connection = mysql://${SERVICE_USER}:${SERVICE_PASSWORD}@${DATABASE_HOST}/${DATABASE}" ${GLANCE_REGISTRY_CONFIG_PATH}
    # edit the [keystone_authtoken] section
    sed -i -r "s|^(#? *)(auth_uri)( *= *)(.*)|auth_uri = http://${CONTROLLER_IP}:5000/v2.0" ${GLANCE_REGISTRY_CONFIG_PATH}
    sed -i -r "s|^(#? *)(identity_uri)( *= *)(.*)|identity_uri = http://${CONTROLLER_IP}:35357" ${GLANCE_REGISTRY_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_tenant_name)( *= *)(.*)|admin_tenant_name = ${SERVICE_TENANT}" ${GLANCE_REGISTRY_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_user)( *= *)(.*)|admin_user = ${SERVICE_USER}" ${GLANCE_REGISTRY_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_password)( *= *)(.*)|admin_password = ${SERVICE_PASSWORD}" ${GLANCE_REGISTRY_CONFIG_PATH}
    # edit [paste_deploy] section 
    sed -i -r "s|^(#? *)(flavor)( *= *)(.*)|flavor = keystone" ${GLANCE_REGISTRY_CONFIG_PATH}
    
    sed -i -r "s|^(#? *)(verbose)( *= *)(.*)|verbose = True" ${GLANCE_REGISTRY_CONFIG_PATH}
    
    #sed -i -r "s|^(#? *)(debug)( *= *)(.*)|debug = True" ${GLANCE_REGISTRY_CONFIG_PATH}
fi


# =================
# Sync the database
# =================
glance-manage db_sync


# =========================
# Restart the image service
# =========================
service glance-registry restart
service glance-api restart

rm -f /var/lib/glance/glance.sqlite

# =============
# Check service
# =============
#RESULT=$(netstat -tnpl | grep ${SERVICE_PUBLIC_PORT})
#if [ -z ${RESULT} ];then
#   echo "[Error] glance service is not working successful."
#   echo "${RESULT}"
#   exit 1
#fi
exit 0
