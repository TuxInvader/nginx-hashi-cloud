variable "prefix" {
  description = "A prefix used for all resources in this example"
}

variable "region" {
  description = "The AWS Region in which all resources in this example should be provisioned"
}

variable "manager" {
  description = "The control plane for the NGINX instances. Options are: none, nim, controller."
  default = "none"
  validation {
    condition = (
      var.manager == "none" || var.manager == "nim" || var.manager == "controller"
    )
    error_message = "The manager option should be one of: none, nim, controller."
  }
}

variable "clusters" {
  description = "The number of Kubernetes clusters to deploy (default=1, max=10)."
  default = 1
  validation {
    condition = (
      var.clusters >= 0 && var.clusters <=10
    )
    error_message = "Clusters must be between 0 and 10."
  }
}

variable "nginxs" {
  description = "The number of NGINX instances to deploy."
  default = 1
  validation {
    condition = (
      var.nginxs >= 0 && var.nginxs <=10
    )
    error_message = "NGINXs must be between 0 and 10."
  }
}

variable "nims" {
  description = "The number of NGINX Instance Managers to deploy."
  default = 0
  validation {
    condition = (
      var.nims >= 0 && var.nims <=10
    )
    error_message = "NIMs must be between 0 and 10."
  }
}

variable "cluster_nodes" {
  description = "The number of K8s nodes to deploy (default=1, max=250)"
  default = 2
  validation {
    condition = (
      var.cluster_nodes >= 0 && var.cluster_nodes <=250
    )
    error_message = "Nodes must be between 0 and 250."
  }
}

variable "controllers" {
  description = "The number of NGINX Controllers to deploy."
  default = 0
  validation {
    condition = (
      var.controllers >= 0 && var.controllers <=10
    )
    error_message = "Clusters must be between 0 and 10."
  }
}

variable "controller_size" {
  description = "The image size for the controller VMS"
  default = "Standard_D4s_v3"
}

variable "nginx_size" {
  description = "The image size for the NGINX VMs"
  default = "Standard_DS1_v2"
}

variable "nim_size" {
  description = "The image size for the NIM VMs"
  default = "Standard_DS2_v2"
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

variable "nim_image" {
  description = "The NGINX Instance Manager image"
}

variable "nim_name" {
  description = "hostname for the nim instance(s)"
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

variable "manager_admin_user" {
  description = "The admin user email address. Needed if Terrorform needs to install/license Controller or NIM."
  default = "ChangeMeIfTerrorformIsInstallingController"
}

variable "manager_admin_pass" {
  description = "The admin user password. Leave blank to autogenerate a password. If you installed controller during packer build, this needs to match the password used in packer."
  default = ""
}

variable "controller_token" {
  description = "Your controller assosciation token or base64 encoded license file. If provided the controller will be licensed at startup"
  default = ""
}
