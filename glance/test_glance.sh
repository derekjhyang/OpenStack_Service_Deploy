#!/usr/bin/env bash

mkdir /tmp/images
cd /tmp/images
#wget http://cdn.download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
#wget --no-check-certificate https://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
aria2c --check-certificate=false -x 16  https://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
source ~/admin-openrc.sh

glance image-create --name "cirros-0.3.3-x86_64" --file cirros-0.3.3-x86_64-disk.img \
  --disk-format qcow2 --container-format bare --is-public True --progress

glance image-list

rm -rf /tmp/images
