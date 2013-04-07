#!/usr/bin/env bash
# author: winnie yang
# [description]
#     restart sameved service in openstack
#
#

Usage() {
    echo "Usage: $0 (keystone|nova|glance|cinder|swift|quantum)"
}


case $1 in
    keystone|nova|glance|cinder|swift|quantum)
        for s in $(service --status-all 2>&1 | grep "$1" | awk '{print $NF}')
        do
           service ${s} restart
        done
    ;;
    *)
        Usage
    ;;
esac
