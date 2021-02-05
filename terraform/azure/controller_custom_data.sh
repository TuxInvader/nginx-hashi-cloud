#!/bin/bash

function license_controller() {
  
  curl -kvv -X POST -f -c /var/run/cloud-init/cookie.jar \
    -H 'Content-type: application/json' \
    -d '{ 
      "credentials":{ 
        "type":"BASIC", 
        "username":"${controller_admin_user}", 
        "password":"${controller_admin_pass}"
      }}' \
    https://${hostname}.${domain}/api/v1/platform/login

  grep session /var/run/cloud-init/cookie.jar >/dev//null 2>&1 || return 1

  curl -kvv -X PUT -f -b /var/run/cloud-init/cookie.jar \
    -H 'Content-type: application/json' \
    -d '{
      "metadata": {
        "name": "license"
      }, "desiredState": {
        "content": "${controller_token}"
      }}' \
    https://${hostname}.${domain}/api/v1/platform/license

    return $?
}

echo ${hostname} > /etc/hostname
echo "${ipaddr}  ${hostname} ${hostname}.${domain}" >> /etc/hosts
hostname ${hostname}

if [ "${install_needed}" == "true" ]
then
  su - nginx -c '/opt/nginx-install/controller_install.sh "${install_needed}" "${hostname}.${domain}" "${controller_admin_user}" "${controller_admin_pass}"'
else
  mkdir /home/${username}/.kube
  cp /etc/kubernetes/admin.conf /home/${username}/.kube/config
  chown -R ${username} /home/${username}/.kube
  
  systemctl start kubelet.service
  systemctl enable kubelet.service

  # Give controller a couple of minutes to startup
  sleep 120
fi

if [ "${controller_token}" != "" ]
then
  until license_controller
  do 
    sleep 10
  done
  rm /var/run/cloud-init/cookie.jar
fi
