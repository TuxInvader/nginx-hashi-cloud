# README

## Deploy Azure Environment

To deploy NGINX Controller, NGINX Plus and some Kubernetes Clusters in Azure.

Copy and edit terraform_tfvars.example to terraform.tfvars, and then run


```
terraform init
terraform plan -out tf.plan
terraform apply tf.plan
```


