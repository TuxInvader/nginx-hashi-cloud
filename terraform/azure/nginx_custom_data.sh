#!/bin/bash

function register_with_controller() {

  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S ==================== REGISTER ==========================="
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
    https://${controller_name}.${domain}/api/v1/platform/login

  grep session /var/run/cloud-init/cookie.jar >/dev//null 2>&1 || return 1
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Controller Login SUCCESS"

  result=1
  completed=0
  attempts=0
  while [ $completed -eq 0 ]
  do
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    date +"%Y-%m-%d %H:%M:%S Controller License status GET"
    curl -kvv -f -b /var/run/cloud-init/cookie.jar https://${controller_name}.${domain}/api/v1/platform/license > /var/run/cloud-init/ctrl-license.log
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

  if [ $result -eq 0 ]
  then

    date +"%Y-%m-%d %H:%M:%S ========================================================="
    date +"%Y-%m-%d %H:%M:%S Controller Download Installer Script"
    curl -f -k -sS -L https://${controller_name}.${domain}/install/controller-agent > /var/run/cloud-init/install.sh
    result=$?

    if [ $result -eq 0 ]
    then

      date +"%Y-%m-%d %H:%M:%S ========================================================="
      date +"%Y-%m-%d %H:%M:%S Controller Download Installer Script - SUCCESS"
      date +"%Y-%m-%d %H:%M:%S Controller Getting API Key"

      API_KEY=$(curl -kvv -f -b /var/run/cloud-init/cookie.jar \
        https://${controller_name}.${domain}/api/v1/platform/global | jq .desiredState.agentSettings.apiKey)
      export API_KEY

      if [ "${nginx_location}" == "" ]
      then
        date +"%Y-%m-%d %H:%M:%S ========================================================="
        date +"%Y-%m-%d %H:%M:%S NGINX Register. Location: unspecified"
        sh /var/run/cloud-init/install.sh -i ${hostname} -l unspecified
        result=$?
      else
        date +"%Y-%m-%d %H:%M:%S ========================================================="
        date +"%Y-%m-%d %H:%M:%S NGINX Location: ${nginx_location} (creating)"
        curl -kvv -X PUT -f -b /var/run/cloud-init/cookie.jar \
          -H 'Content-type: application/json' \
          -d '{
            "metadata": {
              "name": "${nginx_location}"
            }, "desiredState": {
              "type": "OTHER_LOCATION"
            }}' \
          https://${controller_name}.${domain}/api/v1/infrastructure/locations/${nginx_location}
    
        result=$?
        if [ $result -eq 0 ] 
        then
          date +"%Y-%m-%d %H:%M:%S ========================================================="
          date +"%Y-%m-%d %H:%M:%S NGINX Register. Location: ${nginx_location}"
          sh /var/run/cloud-init/install.sh -i ${hostname} -l ${nginx_location}
          result=$?
        fi
      fi
    else
      date +"%Y-%m-%d %H:%M:%S ========================================================="
      date +"%Y-%m-%d %H:%M:%S Controller Download Installer Script - FAILED"
    fi
  fi
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S NGINX Registration Result: $result"
  return $result
  
}

echo ${hostname} > /etc/hostname
echo "${ipaddr}  ${hostname} ${hostname}.${domain}" >> /etc/hosts
hostname ${hostname}

if [ "${controller_token}" != "" ]
then
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Starting Registration Loop...."
  until register_with_controller
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
