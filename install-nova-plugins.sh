#!/usr/bin/env bash

# [Purpose] 
#   install NOVA plugins(includes xenapi, networking...) to Xenserver hypervisor
#

# [Description]
#   When using Xen as the hypervisor for OpenStack Compute, you can install a Python script 
#   (usually, but it can be any executable) on the host side, and then call that through the ``XenAPI``. 
#
#   These scripts are called plugins. The XenAPI plugins live in the nova code repository. 
#
#   These plugins have to be copied to the hypervisor's Dom0, to the appropriate directory, where xapi can find them. 
#   (There are several options for the installation.)
#

# [WARNING]
#   1. ensure that the version of the plugins are in line with the nova installation 
#      by only installing plugins from a matching nova repository.
#
#   2. this script must make all the Xenserver ssh with passwordless
#


set -x

THIS_DIR=$(pwd)


#========================================#
# check xenserver list we want to deploy #
#========================================#
#XENSERVER_LIST=${THIS_DIR}/xenserver_list
#if [ ! -f ${XENSERVER_LIST} ];then
#    echo "Error: deploy failure, we can't find the xenserver list"
#    exit 1
#fi


#====================================#
# create temporary files/directories #
#====================================#
NOVA_ZIPBALL=$(mktemp)
NOVA_SOURCES=$(mktemp -d)


#============================================#
# retrieve NOVA src and make it as a zipball #
#============================================#
#Installation-1: get the source from github.
NOVA_REPO="https://github.com/openstack/nova/archive/master.zip"
wget -qO ${NOVA_ZIPBALL} ${NOVA_REPO}
unzip ${NOVA_ZIPBALL} -d ${NOVA_SOURCES}

# Installation-2: get the source from Ubuntu repo (this MUST run in Ubuntu)
#cd ${NOVA_SOURCES} && sudo apt-get source nova --download-only
#for archive in *.tar.gz;
#do
#    tar -zxf ${archive}
#done

#================#
# inject plugins #
#================#
## xapi.d ##
XAPID_PLUGIN_PATH=$(find ${NOVA_SOURCES} -path '*/xapi.d/plugins' -type d -print)
chmod +x ${XAPID_PLUGIN_PATH} 
cp ${XAPID_PLUGIN_PATH}/* /etc/xapi.d/plugins/

## init.d ##
INITD_PLUGIN_PATH=$(find ${NOVA_SOURCES} -path '*/init.d' -type d -print)
chmod +x ${INITD_PLUGIN_PATH}
cp ${INITD_PLUGIN_PATH}/* /etc/init.d/

## sysconfig ##
SYSCONFIG_PLUGIN_PATH=$(find ${NOVA_SOURCES} -path '*/sysconfig' -type d -print)
chmod +x ${SYSCONFIG_PLUGIN_PATH}
cp ${SYSCONFIG_PLUGIN_PATH}/* /etc/sysconfig/

## udev ##
UDEV_PLUGIN_PATH=$(find ${NOVA_SOURCES} -path '*/udev/rules.d' -type d -print)
chmod +x ${UDEV_PLUGIN_PATH}
cp ${UDEV_PLUGIN_PATH}/* /etc/udev/rules.d/

## xensource ##
XENSOURCE_PLUGIN_PATH=$(find ${NOVA_SOURCES} -path '*/xensource/scripts' -type d -print)
chmod +x ${XENSOURCE_PLUGIN_PATH}
cp ${XENSOURCE_PLUGIN_PATH}/* /etc/xensource/scripts/


#==========================================#
# copy the plugins to xenserver hypervisor #
#==========================================#
#exec < ${XENSERVER_LIST}
#while read XENSERVER
#do 
    #tar -zcvf - -C ${XAPID_PLUGIN_PATH} ./  | ssh "${XENSERVER}" tar -zxvf - -C /etc/xapi.d/plugins/
    #tar -zcvf - -C ${INITD_PLUGIN_PATH} ./  | ssh "${XENSERVER}" tar -zxvf - -C /etc/init.d/
    #tar -zcvf - -C ${SYSCONFIG_PLUGIN_PATH} ./ | ssh "${XENSERVER}" tar -zxvf - -C /etc/sysconfig/
    #tar -zcvf - -C ${UDEV_PLUGIN_PATH} ./ | ssh "${XENSERVER}" tar -zxvf - -C /etc/udev/rules.d/
    #tar -zcvf - -C ${XENSOURCE_PLUGIN_PATH} ./ | ssh "${XENSERVER}" tar -zxvf - -C /etc/xensource/scripts/
    # remote execute the local shell to enable ``ip forwarding``
    #ssh ${XENSERVER} bash < enable_ip_forwarding.sh
    # remote execute command to install ``aprtables`` and ``ebtables`` 
    #echo "yum --enablerepo=base install -y arptables_jf; yum --enablerepo=base install -y ebtables" | ssh ${XENSERVER} bash
#done


#========================================#
# remove the temporary files/directories #
#========================================#
rm ${NOVA_ZIPBALL}
rm -rf ${NOVA_SOURCES}
