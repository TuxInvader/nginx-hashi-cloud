#!/bin/bash
set -x

export CONTROLLER_FIRSTNAME=Buck
export CONTROLLER_SURNAME=Rogers

export CONTROLLER_HOSTNAME=$1
export CONTROLLER_USERNAME=$2
export CONTROLLER_PASSWORD=$3

cd /opt
tar zxvpf controller-installer.tar.gz
until controller-installer/install.sh -n -m 127.0.0.1 -x 12321 -b false -g false -j $CONTROLLER_USERNAME -e $CONTROLLER_USERNAME -p $CONTROLLER_PASSWORD -f $CONTROLLER_HOSTNAME -t $CONTROLLER_FIRSTNAME -u $CONTROLLER_SURNAME -c -w -y --configdb-volume-type local --tsdb-volume-type local -a NGINX ; do sleep 10 ; done


