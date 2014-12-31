#!/usr/bin/env bash
# author: Derrick Yang

# enable trace
set -x 

DATABASE_HOST=localhost
DATABASE_USER=root
DATABASE_PASSWORD=root
DATABASE=cinder

SERVICE_USER=cinder
SERVICE_PASSWORD=cinder
SERVICE_PUBLIC_PORT=8776
SERVICE_INTERNAL_PORT=8776
SERVICE_ADMIN_PORT=8776
SERVICE_CONFIG_PATH=/etc/${SERVICE_USER}/${SERVICE_USER}.conf

CONTROLLER_IP=localhost

CINDER_PUBLIC_URL_V1=http://${CONTROLLER_IP}:${SERVICE_PUBLIC_PORT}/v1/%\(tenant_id\)s
CINDER_INTERNAL_URL_V1=http://${CONTROLLER_IP}:${SERVICE_INTERNAL_PORT}/v1/%\(tenant_id\)s
CINDER_ADMIN_URL_V1=http://${CONTROLLER_IP}:${SERVICE_ADMIN_PORT}/v1/%\(tenant_id\)s

CINDER_PUBLIC_URL_V2=http://${CONTROLLER_IP}:${SERVICE_PUBLIC_PORT}/v2/%\(tenant_id\)s
CINDER_INTERNAL_URL_V2=http://${CONTROLLER_IP}:${SERVICE_INTERNAL_PORT}/v2/%\(tenant_id\)s
CINDER_ADMIN_URL_V2=http://${CONTROLLER_IP}:${SERVICE_ADMIN_PORT}/v2/%\(tenant_id\)s

ENDPOINT_REGION=RegionOne


# ===============
# Create database
# ===============
mysql -h ${DATABASE_HOST} -u ${DATABASE_USER} -p${DATABASE_PASSWORD} \
      -e "DROP DATABASE IF EXISTS ${DATABASE};"\
"CREATE DATABASE ${DATABASE};"\
"GRANT ALL PRIVILEGES ON ${DATABASE}.* TO '${SERVICE_USER}'@'localhost' IDENTIFIED BY '${SERVICE_PASSWORD}';"\
"GRANT ALL PRIVILEGES ON ${DATABASE}.* TO '${SERVICE_USER}'@'%' IDENTIFIED BY '${SERVICE_PASSWORD}';"


source admin-openrc.sh

# a. Create the cinder user.
keystone user-create --name ${SERVICE_USER} --pass ${SERVICE_PASSWORD}
# b. Link the cinder user to the service tenant and admin role.
keystone user-role-add --user ${SERVICE_USER} --tenant ${SERVICE_TENANT} --role ${SERVICE_ROLE}
# c. Create the cinder service.
keystone service-create --name ${SERVICE_USER} --type volume --description "OpenStack Block Storage"
keystone service-create --name ${SERVICE_USER}v2 --type volumev2 --description "OpenStack Block Storage"
# d. Create the service API endpoints.
keystone endpoint-create \
--service-id $(keystone service-list | awk '/volume/{print $2}') \
--publicurl ${CINDER_PUBLIC_URL_V1} \
--internalurl ${CINDER_INTERNAL_URL_V1} \
--adminurl ${CINDER_ADMIN_URL_V1} \
--region ${ENDPOINT_REGION}
keystone endpoint-create \
--service-id $(keystone service-list | awk '/volumev2/{print $2}') \
--publicurl ${CINDER_PUBLIC_URL_V2} \
--internalurl ${CINDER_INTERNAL_URL_V2} \
--adminurl ${CINDER_ADMIN_URL_V2} \
--region ${ENDPOINT_REGION}



# ================
# Install Packages
# ================
apt-get install -y cinder-api cinder-scheduler python-cinderclient

# ============================
# Edit the configuration files
# ============================
if [ -f ${SERVICE_CONFIG_PATH} ];then
    # edit database access
    sed -i -r "s|^(#? *)(connection)( *= *)(.*)|connection = mysql://${SERVICE_USER}:${SERVICE_PASSWORD}@${DATABASE_HOST}/${DATABASE}|g" ${SERVICE_CONFIG_PATH}
    # configure RabbitMQ
    sed -i -r "s|^(#? *)(rpc_backend)( *= *)(.*)|rpc_backend = rabbit|g" ${SERVICE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(rabbit_host)( *= *)(.*)|rabbit_host = ${CONTROLLER_IP}|g" ${SERVICE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(rabbit_password)( *= *)(.*)|rabbit_password = ${RABBIT_PASSWORD}|g" ${SERVICE_CONFIG_PATH}
    # configure [keystone_authtoken] section
    sed -i -r "s|^(#? *)(auth_strategy)( *= *)(.*)|auth_strategy = keystone|g" ${SERVICE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(auth_uri)( *= *)(.*)|auth_uri = http://${CONTROLLER_IP}:5000/v2.0|g" ${SERVICE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(identity_uri)( *= *)(.*)|identity_uri = http://${CONTROLLER_IP}:35357|g" ${SERVICE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_tenant_name)( *= *)(.*)|admin_tenant_name = ${SERVICE_TENANT}|g" ${SERVICE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_user)( *= *)(.*)|admin_user = ${SERVICE_USER}|g" ${SERVICE_CONFIG_PATH}
    sed -i -r "s|^(#? *)(admin_password)( *= *)(.*)|admin_password = ${SERVICE_PASSWORD}|g" ${SERVICE_CONFIG_PATH}
    # In the [DEFAULT] section, configure the my_ip option to use the management interface IP address of the controller node 
    sed -i -r "s|^(#? *)(my_ip)( *= *)(.*)|my_ip = ${CONTROLLER_IP}|g" ${SERVICE_CONFIG_PATH}
    #(Optional) enable verbose logging
    sed -i -r "s|^(#? *)(verbose)( *= *)(.*)|verbose = True|g" ${SERVICE_CONFIG_PATH}
fi

# =============
# Sync database
# =============
cinder-manage db sync

# ================
# Restart services
# ================
service cinder-scheduler restart
service cinder-api restart

