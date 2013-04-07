#!/usr/bin/env bash

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

#===================================================================#
# setting 'Public / Admin / Internal' URLs for each "Endpoint URLs" #
#===================================================================#
# - public URL:
# - admin URL:
# - internal URL:
#

# Usage: create_endpoint <service> <service-id>
create_endpoint () {
    case $1 in
        keystone)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${KEYSTONE_ADMIN_URL} \
                                     --adminurl ${KEYSTONE_ADMIN_URL} \
                                     --internalurl ${KEYSTONE_INTERNAL_URL}  
        ;;
        nova)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${NOVA_PUBLIC_URL} \
                                     --adminurl ${NOVA_ADMIN_URL} \
                                     --internalurl ${NOVA_INTERNAL_URL}
        ;;
        nova-volume)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${NOVA_VOLUME_PUBLIC_URL} \
                                     --adminurl ${NOVA_VOLUME_ADMIN_URL} \
                                     --internalurl ${NOVA_VOLUME_INTERNAL_URL}
        ;;
        cinder)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${CINDER_PUBLIC_URL} \
                                     --adminurl ${CINDER_ADMIN_URL} \
                                     --internalurl ${CINDER_INTERNAL_URL}
        ;;
        glance)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${GLANCE_PUBLIC_URL} \
                                     --adminurl ${GLANCE_ADMIN_URL} \
                                     --internalurl ${GLANCE_INTERNAL_URL}
        ;;
        swift)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${SWIFT_PUBLIC_URL} \
                                     --adminurl ${SWIFT_ADMIN_URL} \
                                     --internalurl ${SWIFT_INTERNAL_URL}
        ;;
        ec2)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${AWS_EC2_PUBLIC_URL} \
                                     --adminurl ${AWS_EC2_ADMIN_URL} \
                                     --internalurl ${AWS_EC2_INTERNAL_URL}
        ;;
        quantum)
            keystone --token ${KEYSTONE_TOKEN} \
                     --endpoint ${KEYSTONE_ADMIN_URL} \
                     endpoint-create --region ${KEYSTONE_REGION} \
                                     --service-id $2 \
                                     --publicurl ${QUANTUM_PUBLIC_URL} \
                                     --adminurl ${QUANTUM_ADMIN_URL} \
                                     --internalurl ${QUANTUM_INTERNAL_URL}
        ;;
    esac
}


#====================================#
# Create endpoints for each services #
#====================================#
#for S in NOVA EC2 SWIFT GLANCE VOLUME KEYSTONE
#do
#    ID=$(keystone --token ${KEYSTONE_TOKEN} \
#                  --endpoint ${KEYSTONE_ADMIN_URL} \
#                  service-list | grep -i "\ $S\ " | awk '{print $2}')
#    PUBLIC=$(eval echo \$${S}_PUBLIC_URL)
#    ADMIN=$(eval echo \$${S}_ADMIN_URL)
#    INTERNAL=$(eval echo \$${S}_INTERNAL_URL)
#    echo "ID: $ID, PUBLIC: $PUBLIC, ADMIN: $ADMIN, INTERNAL: $INTERNAL"
#
#    keystone --token ${KEYSTONE_TOKEN} \
#             --endpoint ${KEYSTONE_ADMIN_URL} \
#             endpoint-create --region nova \
#                             --service_id $ID \
#                             --publicurl $PUBLIC \
#                             --adminurl $ADMIN \
#                             --internalurl $INTERNAL
#
#done


for service in ${SAMEVED_ALL_SERVICES}
do
    # get service-id for each service
    SERVICE_ID=$(keystone --token ${KEYSTONE_TOKEN} \
                          --endpoint ${KEYSTONE_ADMIN_URL} \
                          service-list | grep "${service}" | awk '{print $2}')
    create_endpoint ${service} ${SERVICE_ID}
done
