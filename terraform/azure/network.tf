

// BUG https://github.com/hashicorp/terraform/issues/23506
resource "azurerm_network_security_group" "internet-nsg" {
  name = "internet-nsg"
  resource_group_name = azurerm_resource_group.resgroup.name
  location = azurerm_resource_group.resgroup.location
  security_rule = [ {
    access = "Allow"
    description = "SSH"
    destination_address_prefix = "*"
    destination_address_prefixes = null
    destination_application_security_group_ids = []
    destination_port_range = "22"
    destination_port_ranges = null
    direction = "Inbound"
    name = "SSH"
    priority = 100
    protocol = "Tcp"
    source_address_prefix = null
    source_address_prefixes = var.fw_ssh_prefixes
    source_application_security_group_ids = null
    source_port_range = "*"
    source_port_ranges = null
  },
  {
    access = "Allow"
    description = "Web Services"
    destination_address_prefix = "*"
    destination_address_prefixes = null
    destination_application_security_group_ids = []
    destination_port_range = null
    destination_port_ranges = ["80", "443"]
    direction = "Inbound"
    name = "WebServices"
    priority = 200
    protocol = "Tcp"
    source_address_prefix = null
    source_address_prefixes = var.fw_service_prefixes
    source_application_security_group_ids = null
    source_port_range = "*"
    source_port_ranges = null
  }]
  
}

resource "azurerm_virtual_network" "infra-vnet" {
  name = "infra-vnet"
  resource_group_name = azurerm_resource_group.resgroup.name
  address_space = [ "10.0.0.0/14" ]
  location = azurerm_resource_group.resgroup.location
}

resource "azurerm_subnet" "public" {
  name = "public"
  address_prefixes = [ "10.1.0.0/16" ]
  virtual_network_name = azurerm_virtual_network.infra-vnet.name
  resource_group_name = azurerm_resource_group.resgroup.name
}

resource "azurerm_subnet" "private" {
  name = "private"
  address_prefixes = [ "10.2.0.0/16" ]
  virtual_network_name = azurerm_virtual_network.infra-vnet.name
  resource_group_name = azurerm_resource_group.resgroup.name
}

resource "azurerm_subnet" "management" {
  name = "management"
  address_prefixes = [ "10.0.0.0/16" ]
  virtual_network_name = azurerm_virtual_network.infra-vnet.name
  resource_group_name = azurerm_resource_group.resgroup.name
}

resource "azurerm_subnet_network_security_group_association" "public-internet-nsg" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.internet-nsg.id
}

resource "azurerm_virtual_network" "cntnr-vnet" {
  name = "cntnr-vnet"
  resource_group_name = azurerm_resource_group.resgroup.name
  address_space = [ "192.168.0.0/20" ]
  location = azurerm_resource_group.resgroup.location
}

resource "azurerm_virtual_network_peering" "cntnr-infra" {
  name                      = "cntnr-infra"
  resource_group_name       = azurerm_resource_group.resgroup.name
  virtual_network_name      = azurerm_virtual_network.cntnr-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.infra-vnet.id
}

resource "azurerm_virtual_network_peering" "infra-cntnr" {
  name                      = "infra-cntnr"
  resource_group_name       = azurerm_resource_group.resgroup.name
  virtual_network_name      = azurerm_virtual_network.infra-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.cntnr-vnet.id
}

