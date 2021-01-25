variable "prefix" {
  description = "A prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
}

variable "clusters" {
  description = "The number of Kubernetes clusters to deploy."
}

variable "nginxs" {
  description = "The number of NGINX instances to deploy."
}

variable "controllers" {
  description = "The number of Controllers to deploy."
}

variable "controller_size" {
  description = "The image size for the controller VMS"
  default = "Standard_D4s_v3"
}

variable "nginx_size" {
  description = "The image size for the NGINX VMs"
  default = "Standard_DS1_v2"
}

variable "pod_net_offset" {
  default = "240"
  description = "The starting point for the kubernetes pod_cidr"
}

variable "image_rg" {
  description = "The resource group where Virtual Machine images are stored"
}

variable "controller_image" {
  description = "The NGINX Controller image"
}

variable "controller_name" {
  description = "hostname for the controller"
}

variable "nginx_name" {
  description = "hostname for the nginx instance(s)"
}

variable "fw_ssh_prefixes" {
  description = "Firewall SSH Source prefixes for access"
}

variable "fw_service_prefixes" {
  description = "Firewall Service Source prefixes for access"
}

variable "admin_user" {
  description = "The username for the linux user"
  default = "nginx"
}

variable "admin_ssh_key" {
  description = "The SSH key for the admin_user"
}