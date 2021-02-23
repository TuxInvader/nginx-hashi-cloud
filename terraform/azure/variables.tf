variable "prefix" {
  description = "A prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
}

variable "clusters" {
  description = "The number of Kubernetes clusters to deploy (default=1, max=10)."
  default = 1
  validation {
    condition = (
      var.clusters >= 0 && var.clusters <=10
    )
    error_message = "Clusters must be between 1 and 10."
  }
}

variable "nginxs" {
  description = "The number of NGINX instances to deploy."
}

variable "cluster_nodes" {
  description = "The number of K8s nodes to deploy (default=1, max=250)"
  default = 1
  validation {
    condition = (
      var.cluster_nodes >= 0 && var.cluster_nodes <=250
    )
    error_message = "Nodes must be between 1 and 250."
  }
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

variable "nginx_image" {
  description = "The NGINX Plus image"
}

variable "nginx_name" {
  description = "hostname for the nginx instance(s)"
}

variable "nginx_location" {
  description = "Controller location for registering with NGINX Controller"
  default = ""
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

variable "install_needed" {
  description = "Does Terraform need to run the controller installer during first boot?"
  default = "false"
}

variable "controller_admin_user" {
  description = "The admin user email address. Only needed if install_needed is true or you set a controller_token for auto-licensing"
  default = "ChangeMeIfInstallNeededIsTrue"
}

variable "controller_admin_pass" {
  description = "The admin user password. Only needed if install_needed is true or you set a controller_token for auto-licensing"
  default = "ChangeMeIfInstallNeededIsTrue"
}

variable "controller_token" {
  description = "Your controller assosciation token. If provided the controller will be licensed at startup"
  default = ""
}
