#!/bin/bash

fqdn="${hostname}.${domain}"
[ "${internal_domain}" = "true" ] && fqdn="${hostname}.internal.cloudapp.net"
export fqdn

admin_pass="${manager_admin_pass}"
[ "${manager_admin_pass}" = "" ] && admin_pass="${manager_random_pass}"
export admin_pass

other_pass=${manager_other_pass}
export other_pass

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

rm /etc/nms/nginx/.htpasswd
htpasswd -c -b /etc/nms/nginx/.htpasswd "admin" "$${admin_pass}"
htpasswd -b /etc/nms/nginx/.htpasswd "deborah" "$${admin_pass}"
htpasswd -b /etc/nms/nginx/.htpasswd "simon" "$${admin_pass}"
htpasswd -b /etc/nms/nginx/.htpasswd "gitdev" "$${other_pass}"
htpasswd -b /etc/nms/nginx/.htpasswd "gitops" "$${other_pass}"

echo "10.1.0.4  acm.mbngx1.uksouth.cloudapp.azure.com" >> /etc/hosts
echo "10.1.0.5  acm.mbngx2.uksouth.cloudapp.azure.com" >> /etc/hosts

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S Enable the test repo"

if [ "$${enable_test_repo}" = "true" ]
then
   cat /etc/apt/apt.conf.d/90pkgs-nginx | sed -re 's/pkgs/pkgs-test/g' > /etc/apt/apt.conf.d/90pkgs-test-nginx
   echo "deb https://pkgs-test.nginx.com/adm/ubuntu $(lsb_release -cs) nginx-plus" > /etc/apt/sources.list.d/pkgs-test-nginx.list
fi

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S ==================== COMPLETE ==========================="
date +"%Y-%m-%d %H:%M:%S ========================================================="

