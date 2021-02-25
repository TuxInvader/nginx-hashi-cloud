#!/bin/bash

fqdn="${hostname}.${domain}"
[ "${internal_domain}" == "true" ] && fqdn="${hostname}.internal.cloudapp.net"
export fqdn

function put_license() {
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Putting Controller License"
  curl -kvv -X PUT -f -b /var/run/cloud-init/cookie.jar \
    -H 'Content-type: application/json' \
    -d '{
      "metadata": {
        "name": "license"
      }, "desiredState": {
        "content": "${controller_token}"
      }}' \
    https://$${fqdn}/api/v1/platform/license > /var/run/cloud-init/ctrl-license.log
    return $?
}

function license_controller() {
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S ==================== LICENSE ============================"
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Controller Login"
  curl -kvv -X POST -f -c /var/run/cloud-init/cookie.jar \
    -H 'Content-type: application/json' \
    -d '{ 
      "credentials":{ 
        "type":"BASIC", 
        "username":"${controller_admin_user}", 
        "password":"${controller_admin_pass}"
      }}' \
    https://$${fqdn}/api/v1/platform/login

  grep session /var/run/cloud-init/cookie.jar >/dev//null 2>&1 || return 1
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Controller Login SUCCESS"

  put_license
  result=1
  completed=0
  attempts=0
  while [ $completed -eq 0 ] 
  do
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    date +"%Y-%m-%d %H:%M:%S Controller License status GET"
    curl -kvv -f -b /var/run/cloud-init/cookie.jar https://$${fqdn}/api/v1/platform/license > /var/run/cloud-init/ctrl-license.log
    grep '"isError":true' /var/run/cloud-init/ctrl-license.log >/dev/null
    if [ $? -eq 0 ]
    then
      date +"%Y-%m-%d %H:%M:%S ========================================================="
      date +"%Y-%m-%d %H:%M:%S Controller License status ERROR (Putting new license)"
      put_license
      sleep 5
    fi
    grep '"isConfigured":true' /var/run/cloud-init/ctrl-license.log >/dev/null
    if [ $? -eq 0 ]
    then
      date +"%Y-%m-%d %H:%M:%S ========================================================="
      date +"%Y-%m-%d %H:%M:%S Controller License status SUCCESS"
      completed=1 
      result=0
    elif [ $attempts -gt 3 ]
    then
      date +"%Y-%m-%d %H:%M:%S ========================================================="
      date +"%Y-%m-%d %H:%M:%S Controller License status FAILED"
      completed=1 
      result=1
    else
      attempts=$(( $attempts + 1 ))
      sleep 10
    fi
  done
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Controller License Result: $result"
  return $result
}

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S Setting WAAgent to monitor Hostname and restarting service"
date +"%Y-%m-%d %H:%M:%S See: https://github.com/Azure/WALinuxAgent/issues/1398 "
date +"%Y-%m-%d %H:%M:%S See: https://github.com/Azure/WALinuxAgent/issues/119 "
sed -i -re 's/Provisioning.MonitorHostName=n/Provisioning.MonitorHostName=y/' /etc/waagent.conf
systemctl restart walinuxagent.service

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S Ensure the Hostname is correct"

date +"%Y-%m-%d %H:%M:%S Hostname was: $(hostname)"
echo ${hostname} > /etc/hostname
hostnamectl set-hostname ${hostname}
date +"%Y-%m-%d %H:%M:%S Hostname now: $(hostname)"

if [ "${install_needed}" == "true" ]
then
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Install Needed - Installing Controller"
  su - ${username} -c "/opt/nginx-install/controller_install.sh \"${install_needed}\" \"$${fqdn}\" \"${controller_admin_user}\" \"${controller_admin_pass}\""
else
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Controller Installed by Packer"
  date +"%Y-%m-%d %H:%M:%S Starting Kubernetes"
  mkdir /home/${username}/.kube
  cp /etc/kubernetes/admin.conf /home/${username}/.kube/config
  chown -R ${username} /home/${username}/.kube
  
  systemctl start kubelet.service
  systemctl enable kubelet.service

  # Give controller a couple of minutes to startup
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Sleeping for 2 minutes"
  sleep 120
fi

if [ "${controller_token}" != "" ]
then
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Starting Licensing Loop...."
  until license_controller
  do
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    date +"%Y-%m-%d %H:%M:%S ==================== SLEEPING ==========================="
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    sleep 10
  done
  rm /var/run/cloud-init/cookie.jar
fi

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S ==================== COMPLETE ==========================="
date +"%Y-%m-%d %H:%M:%S ========================================================="
