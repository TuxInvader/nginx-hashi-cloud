
resource "azurerm_public_ip" "nginx-public-ips" {
  count               = var.nginxs
  name                = "nginx-public-ip-${count.index}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  allocation_method = "Dynamic"
  domain_name_label = "${var.nginx_name}${count.index}"
}

resource "azurerm_public_ip" "ctrl-public-ips" {
  count               = var.controllers
  name                = "ctrl-public-ip-${count.index}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  allocation_method = "Dynamic"
  domain_name_label = "${var.controller_name}${count.index}"
}

resource "azurerm_network_interface" "nginx-public-nics" {
  count               = var.nginxs
  name                = "nginx-public-nic-${count.index}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name

  ip_configuration {
    name                            = "nginx-public-nic-ip-${count.index}"
    subnet_id                       = azurerm_subnet.public.id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = azurerm_public_ip.nginx-public-ips[count.index].id
  }
}

resource "azurerm_network_interface" "ctrl-mgmnt-nics" {
  count               = var.controllers
  name                = "ctrl-mgmnt-nic-${count.index}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name

  ip_configuration {
    name                          = "ctrl-mgmnt-nic-ip-${count.index}"
    subnet_id                     = azurerm_subnet.management.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    //private_ip_address            = "10.0.0.${format("%02d", count.index + 4)}"
    public_ip_address_id          = azurerm_public_ip.ctrl-public-ips[count.index].id
  }
}

resource "azurerm_network_interface" "ctrl-public-nics" {
  count               = var.controllers
  name                = "ctrl-public-nic-${count.index}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name

  ip_configuration {
    name                          = "ctrl-public-nic-ip-${count.index}"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
  }
}

data "azurerm_image" "ctrl-img" {
  name                = var.controller_image
  resource_group_name = var.image_rg
}

resource "azurerm_linux_virtual_machine" "ctrl-vm" {
  count                 = var.controllers
  name                  = "${var.controller_name}${count.index}"
  location              = azurerm_resource_group.resgroup.location
  resource_group_name   = azurerm_resource_group.resgroup.name
  network_interface_ids = [
    azurerm_network_interface.ctrl-mgmnt-nics[count.index].id,
    azurerm_network_interface.ctrl-public-nics[count.index].id
  ]
  size                  = var.controller_size
  admin_username        = var.admin_user
  source_image_id       = data.azurerm_image.ctrl-img.id

  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.admin_ssh_key)
  } 

  os_disk {
    name              = "ctrl-vhd-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

 # outputs

 output "nginx_public_ips" {
   value = azurerm_public_ip.nginx-public-ips[*].ip_address
 }


 output "ctrl_public_ips" {
   value = azurerm_public_ip.ctrl-public-ips[*].ip_address
 }
