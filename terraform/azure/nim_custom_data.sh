#!/bin/bash

fqdn="${hostname}.${domain}"
[ "${internal_domain}" == "true" ] && fqdn="${hostname}.internal.cloudapp.net"
export fqdn

admin_pass="${manager_admin_pass}"
[ "${manager_admin_pass}" == "" ] && admin_pass="${manager_random_pass}"
export admin_pass

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S Ensure the Hostname is correct"

date +"%Y-%m-%d %H:%M:%S Hostname is: $(hostname)"
if [ "$(hostname)" != "${hostname}" ]
then
  echo ${hostname} > /etc/hostname
  hostnamectl set-hostname ${hostname}
  date +"%Y-%m-%d %H:%M:%S Hostname changed to: $(hostname)"
fi


date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S Update the password"

rm /etc/nginx/nim.passwd
htpasswd -c -b /etc/nginx/nim.passwd "${manager_admin_user}" "$${admin_pass}"

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S ==================== COMPLETE ==========================="
date +"%Y-%m-%d %H:%M:%S ========================================================="

