#!/usr/bin/env bash
# ====================================
#   Create all the required services   
# ====================================
# - Compute: nova, ec2
# - Storage: swift, cinder
# - Image: glance
# - Identity: keystone
# - Networking: quantum 
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

#cat /etc/keystone/keystone.conf | egrep '^admin_token'
#tail -n 5 ~/.bashrc
#exit 0


# nova
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         service-create --name nova \
                        --type compute \
                        --description 'OpenStack Compute Service'
# swift
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         service-create --name swift \
                        --type object-store \
                        --description 'OpenStack Object Storage Service'
# glance
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         service-create --name glance \
                        --type image \
                        --description 'OpenStack Image Service'
# cinder
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         service-create --name cinder \
                        --type volume \
                        --description 'OpenStack Block Storage Service' 
# keystone
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         service-create --name keystone \
                        --type identity \
                        --description 'OpenStack Identity Service'
# ec2
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         service-create --name ec2 \
                        --type ec2 \
                        --description 'Amazon EC2 Service'
# quantum 
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         service-create --name quantum \
                        --type network \
                        --description 'OpenStack Network Service'

             
#======================#
# Create all the roles #
#======================#
# * SAMEVED Identity Management:
#   1. general-user
#   2. advanced-user
#   3. admin
#
for role in ${SAMEVED_ALL_ROLES}
do
    keystone --token ${KEYSTONE_TOKEN} \
             --endpoint ${KEYSTONE_ADMIN_URL} \
             role-create --name ${role}
done

#================================#
# Create 'SAMEVED Admin Tenant'  #
#================================# 
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         tenant-create --name ${ADMIN_TENANT} \
                       --description "SAMEVED Admin Tenant" \
                       --enabled true

#=======================================================#
# Create 'SAMEVED Admin User' with all roles privileges #
#=======================================================#
ADMIN_TENANT_ID=$(keystone --token ${KEYSTONE_TOKEN} \
                           --endpoint ${KEYSTONE_ADMIN_URL} \
                           tenant-list | grep "\ ${ADMIN_TENANT}\ " | awk '{print $2}')
# create 'SAMEVED Admin User'
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         user-create --name ${ADMIN} \
                     --tenant-id ${ADMIN_TENANT_ID} \
                     --pass ${ADMIN_PASSWORD} \
                     --enabled true
                     #--email root@localhost \
                     #--enabled true
#
# make 'SAMEVED Admin User' with all the roles privileges
#
ADMIN_USER_ID=$(keystone --token ${KEYSTONE_TOKEN} \
                         --endpoint ${KEYSTONE_ADMIN_URL} \
                         user-list | grep "\ ${ADMIN}\ " | awk '{print $2}')

for R in ${SAMEVED_ALL_ROLES}
do
    ROLE_ID=$(keystone --token ${KEYSTONE_TOKEN} \
                       --endpoint ${KEYSTONE_ADMIN_URL} \
                       role-list | grep "\ $R\ " | awk '{print $2}')
    keystone --token ${KEYSTONE_TOKEN} \
             --endpoint ${KEYSTONE_ADMIN_URL} \
             user-role-add --user-id ${ADMIN_USER_ID} \
                           --role-id ${ROLE_ID} \
                           --tenant-id ${ADMIN_TENANT_ID}
done                       
                       
                       
#==================================================================#
# create a new 'service tenant' and then                           #
# add the specified service to the corresponding 'service tenant'  #
#==================================================================# 

# Create Service Tenant
keystone --token ${KEYSTONE_TOKEN} \
         --endpoint ${KEYSTONE_ADMIN_URL} \
         tenant-create --name service \
                       --description "SAMEVED Service Tenant" \
                       --enabled true
# Service Tenant ID
SERVICE_TENANT_ID=$(keystone --token ${KEYSTONE_TOKEN} \
                             --endpoint ${KEYSTONE_ADMIN_URL} \
                             tenant-list | grep "\ service\ " | awk '{print $2}')
# Admin Role ID
ADMIN_ROLE_ID=$(keystone --token ${KEYSTONE_TOKEN} \
                         --endpoint ${KEYSTONE_ADMIN_URL} \
                         role-list | grep "\ admin\ " | awk '{print $2}')
#
# create a new user for each service
#
for S in ${SAMEVED_ALL_SERVICES}
do
   keystone --token ${KEYSTONE_TOKEN} \
            --endpoint ${KEYSTONE_ADMIN_URL} \
            user-create --name $S \
                        --pass ${ADMIN_PASSWORD} \
                        --tenant-id ${SERVICE_TENANT_ID} \
                        --enabled true
                        #--email $S@localhost \
                        #--enabled true
   # get service-id
   SERVICE_ID=$(keystone --token ${KEYSTONE_TOKEN} \
                         --endpoint ${KEYSTONE_ADMIN_URL} \
                         user-list | grep "\ $S\ " | awk '{print $2}')
   # Grant admin role to the $S user in the service tenant
   keystone --token ${KEYSTONE_TOKEN} \
            --endpoint ${KEYSTONE_ADMIN_URL} \
            user-role-add --user-id ${SERVICE_ID} \
                          --role-id ${ADMIN_ROLE_ID} \
                          --tenant-id ${SERVICE_TENANT_ID}
done                       
