#!/usr/bin/env bash

EXPORT_PATH=~/admin-openrc.sh
ADMIN_TOKEN=$(cat /etc/keystone/keystone.conf|grep 'admin_token'|awk 'BEGIN{FS="="}{print $2}')
echo -e "export OS_SERVICE_ENDPOINT=http://localhost:35357/v2.0\n"\
"export OS_SERVICE_TOKEN=${ADMIN_TOKEN}" > ${EXPORT_PATH}

chmod +x ${EXPORT_PATH}
