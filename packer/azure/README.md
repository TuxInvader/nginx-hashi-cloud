# README

## Pack Controller

Copy and edit the controller_pkrvars_sample.json to controller.pkrvars.json, and then run:

```
packer build -var-file controller.pkrvars.json pack_controller.json
```

The hostname you use needs to match the hostname you intend to deploy, because controller uses K8s under the hood
and the kubernetes node name can not be changed. You should also use the same IP range as packer, else you'll need
to add an additional IP during boot. Packer uses a 10.0.0.0 subnet, and the host will get 10.0.0.4

If you do have different hosts/ips, you'll need to do something like this between networking startup and kubelet
```
packer_host=tuxctl0
packer_fqdn=tuxctl0.uksouth.cloudapp.azure.com
packer_add=10.0.0.4
packer_host="${packer_host} ${packer_fqdn}"

iface=$(ip route show default | awk '{ print $5 }')
ipadd=$(ip route show default | awk '{ print $9 }')
if [ "${ipadd}" != "10.0.0.4" ]
  ip a add 10.0.0.4/32 dev ${iface}
fi
echo -e '\n10.0.0.4\t${packer_host} ${packer_fqdn}\n' >> /etc/hosts
hostname $packer_host
```

but that may break, and wont allow you to cluster controllers either :-(


