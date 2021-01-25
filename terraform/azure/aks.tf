
resource "azurerm_subnet" "k8s-subnet" {
  count = var.clusters
  name = "${var.prefix}-k8sub-${count.index}"
  address_prefixes = [ "192.168.${count.index}.0/24" ]
  virtual_network_name = azurerm_virtual_network.cntnr-vnet.name
  resource_group_name = azurerm_resource_group.resgroup.name
}

resource "azurerm_kubernetes_cluster" "config" {
  count               = var.clusters
  name                = "${var.prefix}-k8s-${count.index}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  dns_prefix          = "${var.prefix}-k8s-${count.index}"
  
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.k8s-subnet[count.index].id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    pod_cidr = "10.${format("%02d", count.index + var.pod_net_offset)}.0.0/17"
    service_cidr = "10.${format("%02d", count.index + var.pod_net_offset)}.128.0/17"
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip = "10.${format("%02d", count.index + var.pod_net_offset)}.128.10"
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled = false
    }
  }

}

# outputs 

output "k8s_id" {
  value = azurerm_kubernetes_cluster.config[*].id
}

output "k8s_kube_config" {
  value = azurerm_kubernetes_cluster.config[*].kube_config_raw
}

output "k8s_client_key" {
  value = azurerm_kubernetes_cluster.config[*].kube_config.0.client_key
}

output "k8s_client_certificate" {
  value = azurerm_kubernetes_cluster.config[*].kube_config.0.client_certificate
}

output "k8s_cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.config[*].kube_config.0.cluster_ca_certificate
}

output "k8s_host" {
  value = azurerm_kubernetes_cluster.config[*].kube_config.0.host
}