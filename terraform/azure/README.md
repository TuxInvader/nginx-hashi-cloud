# README

This is a terrorform deployment for NGINX Plus with Kubernetes AKS clusters and Controller.

The images for NGINX Plus and NGINX Controller should be built using the instructions in
../../packer/azure


## Deploy Azure Environment

To deploy NGINX Controller, NGINX Plus and some Kubernetes Clusters in Azure.

Copy and edit terraform_tfvars.example to terraform.tfvars, and then run

```
terraform init
terraform plan -out tf.plan
terraform apply tf.plan
```



