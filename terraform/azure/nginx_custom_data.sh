#!/bin/bash

ctrl_fqdn="${controller_name}.${domain}"
[ "${internal_domain}" == "true" ] && ctrl_fqdn="${controller_name}.internal.cloudapp.net"
export ctrl_fqdn

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
    https://$${ctrl_fqdn}/api/v1/platform/login

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
    curl -kvv -f -b /var/run/cloud-init/cookie.jar https://$${ctrl_fqdn}/api/v1/platform/license > /var/run/cloud-init/ctrl-license.log
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
    curl -f -k -sS -L https://$${ctrl_fqdn}/install/controller-agent > /var/run/cloud-init/install.sh && \
    #sed -i -re 's/controller_fqdn="${controller_name}.${domain}"/controller_fqdn="${controller_name}.internal.cloudapp.net"/g' /var/run/cloud-init/install.sh
    result=$?

    if [ $result -eq 0 ]
    then

      date +"%Y-%m-%d %H:%M:%S ========================================================="
      date +"%Y-%m-%d %H:%M:%S Controller Download Installer Script - SUCCESS"
      date +"%Y-%m-%d %H:%M:%S Controller Getting API Key"

      API_KEY=$(curl -kvv -f -b /var/run/cloud-init/cookie.jar \
        https://$${ctrl_fqdn}/api/v1/platform/global | jq .desiredState.agentSettings.apiKey)
      export API_KEY

      if [ "${nginx_location}" == "" ]
      then
        date +"%Y-%m-%d %H:%M:%S ========================================================="
        date +"%Y-%m-%d %H:%M:%S NGINX Register. Location: unspecified"
        sh /var/run/cloud-init/install.sh -y -i ${hostname} -l unspecified
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
          https://$${ctrl_fqdn}/api/v1/infrastructure/locations/${nginx_location}
    
        result=$?
        if [ $result -eq 0 ] 
        then
          date +"%Y-%m-%d %H:%M:%S ========================================================="
          date +"%Y-%m-%d %H:%M:%S NGINX Register. Location: ${nginx_location}"
          sh /var/run/cloud-init/install.sh -y -i ${hostname} -l ${nginx_location}
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
#echo "${ipaddr}  ${hostname} ${hostname}.${domain}" >> /etc/hosts
echo "127.0.1.1  ${hostname} ${hostname}.${domain}" >> /etc/hosts
hostnamectl set-hostname ${hostname}

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
date +"%Y-%m-%d %H:%M:%S Settin up routes for kubernetes"

cat > /etc/rc.local <<EOF
ip route add 10.240.0.0/12 dev eth1 via 10.2.0.1
exit 0
EOF

chmod +x /etc/rc.local
/etc/rc.local

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S ==================== COMPLETE ==========================="
date +"%Y-%m-%d %H:%M:%S ========================================================="
