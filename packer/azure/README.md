# README

## Pack Controller

You can either build an image for a known hostname and IP address that has controller installed and ready to go
or you can build an image which has the installer primed and ready to run on first deployment through cloud init.
The `full_build` setting determines which type is built.

Copy and edit the controller_pkvars.example to controller.pkrvars.json, and then run:

```
packer build -var-file controller.pkrvars.json pack_controller.json
```

if `full_build` is true then the hostname you use needs to match the hostname you intend to deploy, because controller
uses K8s under the hood and the kubernetes node name can not be changed. You should also use the same IP range as 
packer, else you'll need to add an additional IP during boot. Packer uses a 10.0.0.0 subnet, and the host will get 10.0.0.4

Using `full_build` true will boot into controller quickly, but be less flexible. If you want to deploy many instanaces from
the image with dynamic hostname and IP addresses then you should set `full_build` to false here, and set `install_needed`
to true in terraform. That configuration will install controller during first boot.


