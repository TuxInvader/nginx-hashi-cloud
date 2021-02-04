#!/bin/bash

function register_with_controller() {

  curl -k -sS -L https://${hostname}.${domain}/install/controller-agent > /var/run/cloud-init/install.sh
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

  API_KEY=$(curl -kvv -f -b /var/run/cloud-init/cookie.jar \
    https://${hostname}.${domain}/api/v1/platform/global | jq .desiredState.agentSettings.apiKey)
  export API_KEY

  if [ "${nginx_location}" == "" ]
  then
    sh /var/run/cloud-init/install.sh -i ${hostname} -l unspecified
    return $?
  else
    curl -kvv -X PUT -f -b /var/run/cloud-init/cookie.jar \
      -H 'Content-type: application/json' \
      -d '{
        "metadata": {
          "name": "${nginx_location}"
        }, "desiredState": {
          "type": "OTHER_LOCATION"
        }}' \
      https://${hostname}.${domain}/api/v1/infrastructure/locations/${nginx_location}
    
    [ $? -ne 0 ] && return $?
    sh /var/run/cloud-init/install.sh -i ${hostname} -l ${nginx_location}
    return $?
  fi
  
}

echo ${hostname} > /etc/hostname
echo "${ipaddr}  ${hostname} ${hostname}.${domain}" >> /etc/hosts
hostname ${hostname}

if [ "${controller_token}" != "" ]
then
  until register_with_controller
  do 
    sleep 10
  done
  rm /var/run/cloud-init/cookie.jar
fi
