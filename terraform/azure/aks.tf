
resource "azurerm_user_assigned_identity" "identity" {
  name                = "${var.prefix}-identity"
  resource_group_name = azurerm_resource_group.resgroup.name
  location            = azurerm_resource_group.resgroup.location
}

resource "azurerm_role_assignment" "network-contrib-assignment" {
  scope                = azurerm_resource_group.resgroup.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Azure UK has never been a problem, but EU West is slow adding roles, Try sleeping for 60 seconds
resource "time_sleep" "sleep-60" {
  depends_on      = [
    azurerm_role_assignment.network-contrib-assignment
  ]
  create_duration = "60s"
}

resource "azurerm_subnet" "k8s-subnet" {
  count = var.clusters
  name = "${var.prefix}-k8sub-${count.index}"
  address_prefixes = [ "192.168.${count.index}.0/24" ]
  virtual_network_name = azurerm_virtual_network.cntnr-vnet.name
  resource_group_name = azurerm_resource_group.resgroup.name
  depends_on = [
    time_sleep.sleep-60,
    azurerm_subnet_route_table_association.private-routes-assoc
   ]
}

resource "azurerm_subnet_route_table_association" "container-routes-assoc" {
  count          = var.clusters
  subnet_id      = azurerm_subnet.k8s-subnet[count.index].id
  route_table_id = azurerm_route_table.private-route-table.id
}

resource "azurerm_kubernetes_cluster" "config" {
  count                              = var.clusters
  name                               = "${var.prefix}-k8s-${count.index}"
  location                           = azurerm_resource_group.resgroup.location
  resource_group_name                = azurerm_resource_group.resgroup.name
  dns_prefix                         = "${var.prefix}-k8s-${count.index}"
  kubernetes_version                 = var.k8s_version
  role_based_access_control_enabled  = true

  identity {
     type            = "UserAssigned"
     identity_ids    = [
        azurerm_user_assigned_identity.identity.id
     ]
  }

  default_node_pool {
    name           = "default"
    node_count     = var.cluster_nodes
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.k8s-subnet[count.index].id
  }

  depends_on                         = [
    azurerm_role_assignment.network-contrib-assignment
  ]

  network_profile {
    network_plugin = "kubenet"
    pod_cidr = "10.${format("%02d", count.index + var.pod_net_offset)}.0.0/17"
    service_cidr = "10.${format("%02d", count.index + var.pod_net_offset)}.128.0/17"
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip = "10.${format("%02d", count.index + var.pod_net_offset)}.128.10"
  }

}

