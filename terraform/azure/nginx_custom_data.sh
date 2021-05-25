#!/bin/bash

function register_with_nim() {
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S ==================== REGISTER ==========================="
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Install NGINX Agent..."
  apt-get install -y nginx-agent
  echo "c2VydmVyOiBOSU1fU0VSVkVSX1NPQ0tFVAp0bHM6CiAgZW5hYmxlOiBmYWxzZQpsb2c6CiAgbGV2 \
        ZWw6IGluZm8KICBwYXRoOiAvdmFyL2xvZy9uZ2lueC1hZ2VudC8KbWV0YWRhdGE6CiAgbG9jYXRp \
        b246IHVuc3BlY2lmaWVkCnRhZ3M6CiAgLSB3ZWIKbmdpbng6CiAgYmluX3BhdGg6IC91c3Ivc2Jp \
        bi9uZ2lueAogIHBsdXNfYXBpX3VybDogImh0dHA6Ly8xMjcuMC4wLjE6ODA4MC9hcGkiCiAgbWV0 \
        cmljc19wb2xsX2ludGVydmFsOiAxMDAwbXMK" | sed -re 's/\s+//g' | base64 -d | \
        sed -re "s/NIM_SERVER_SOCKET/${nim_name}.internal.cloudapp.net:10001/" > /etc/nginx-agent/nginx-agent.conf

  date +"%Y-%m-%d %H:%M:%S Enabling API on localhost:8080"
  echo "c2VydmVyIHsKICBsaXN0ZW4gODA4MCBkZWZhdWx0OwogIGxvY2F0aW9uIC8geyByZXR1cm4gNDA0 \
        OyB9CiAgbG9jYXRpb24gL2FwaS8geyBhcGkgd3JpdGU9b247IGFsbG93IDEyNy4wLjAuMTsgZGVu \
        eSBhbGw7IH0KfQo=" | sed -re 's/\s+//g' | base64 -d >> /etc/nginx/conf.d/default.conf

  date +"%Y-%m-%d %H:%M:%S Restarting Services"
  systemctl restart nginx
  systemctl restart nginx-agent
  return 0
}

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
        "username":"${manager_admin_user}", 
        "password":"$${admin_pass}"
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
    sed -i -re 's/controller_fqdn="${controller_name}.${domain}"/controller_fqdn="${controller_name}.internal.cloudapp.net"/g' /var/run/cloud-init/install.sh
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

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S ========== Starting userdata script exectution =========="
date +"%Y-%m-%d %H:%M:%S ========================================================="

ctrl_fqdn="${controller_name}.${domain}"
nim_fqdn="${nim_name}.${domain}"
if [ "${internal_domain}" == "true" ]
then
  ctrl_fqdn="${controller_name}.internal.cloudapp.net"
  nim_fqdn="${nim_name}.internal.cloudapp.net"
fi
export ctrl_fqdn
export nim_fqdn

admin_pass="${manager_admin_pass}"
[ "${manager_admin_pass}" == "" ] && admin_pass="${manager_random_pass}"
export admin_pass

date +"%Y-%m-%d %H:%M:%S Setting hostname"
echo ${hostname} > /etc/hostname
echo "127.0.1.1  ${hostname} ${hostname}.${domain}" >> /etc/hosts
hostnamectl set-hostname ${hostname}

if [ "${manager}" == "controller" ]
then
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Starting Controller Registration Loop...."
  until register_with_controller
  do 
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    date +"%Y-%m-%d %H:%M:%S ==================== SLEEPING ==========================="
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    sleep 10
  done
  rm /var/run/cloud-init/cookie.jar
elif [ "${manager}" == "nim" ]
then
  date +"%Y-%m-%d %H:%M:%S ========================================================="
  date +"%Y-%m-%d %H:%M:%S Starting NIM Registration Loop...."
  until register_with_nim
  do
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    date +"%Y-%m-%d %H:%M:%S ==================== SLEEPING ==========================="
    date +"%Y-%m-%d %H:%M:%S ========================================================="
    sleep 10
  done
fi

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S Setting up routes for kubernetes"

cat > /etc/rc.local <<EOF
ip route add 10.240.0.0/12 dev eth1 via 10.2.0.1
exit 0
EOF

chmod +x /etc/rc.local
/etc/rc.local

date +"%Y-%m-%d %H:%M:%S ========================================================="
date +"%Y-%m-%d %H:%M:%S ==================== COMPLETE ==========================="
date +"%Y-%m-%d %H:%M:%S ========================================================="
