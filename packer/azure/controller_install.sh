#!/bin/bash

date "+ %H:%M:%S Controller Installer Starting"
# Exit if arg1 is not true
if [ "$1" != "true" ]
then
  date "+ %H:%M:%S Controller Installer Disabled. Exiting"
  exit
fi

export CONTROLLER_FIRSTNAME=Buck
export CONTROLLER_SURNAME=Rogers
export CONTROLLER_HOSTNAME=$2
export CONTROLLER_USERNAME=$3
export CONTROLLER_PASSWORD=$4

date "+ %H:%M:%S Controller Installer - Extracting"
cd /opt/nginx-install
tar zxvpf controller-installer.tar.gz
date "+ %H:%M:%S Controller Installer - Installing"
until controller-installer/install.sh -n -m 127.0.0.1 -x 12321 -b false -g false -j $CONTROLLER_USERNAME -e $CONTROLLER_USERNAME -p $CONTROLLER_PASSWORD -f $CONTROLLER_HOSTNAME -t $CONTROLLER_FIRSTNAME -u $CONTROLLER_SURNAME -c -w -y --configdb-volume-type local --tsdb-volume-type local -a NGINX ; do sleep 10 ; done

if [ $(whoami) == "packer" ]
then

  # Sleep for 5 minutes before continuing.
  date "+ %H:%M:%S Controller Installer - Waiting for 5 minutes for K8s to settle"
  lastload=$(uptime | sed -re 's/.*average: ([^,]+).*/\1/')
  for sleeps in {01..05}
  do 
    load=$(uptime | sed -re 's/.*average: ([^,]+).*/\1/')
    date "+ %H:%M:%S Sleep $sleeps - Load: $load, Previous: $lastload"
    lastload=$load
    sleep 60
  done

  # This was required becuase cloud-init wasn't setting the hostname at start up due to 
  # https://github.com/Azure/WALinuxAgent/issues/2184. We have a work-around, so leave to start normally.
  # Disable kubernetes at startup. We'll re-enable with cloud-init
  #date "+ %H:%M:%S Controller Installer - Disabling Kubernetes."
  #sudo systemctl disable kubelet.service

fi

date "+ %H:%M:%S Controller Installer Complete."

