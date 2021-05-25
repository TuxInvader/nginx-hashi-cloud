data "azurerm_image" "ctrl-img" {
  name                = var.controller_image
  resource_group_name = var.image_rg
  count               = var.controllers
}

resource "azurerm_public_ip" "ctrl-public-ips" {
  count               = var.controllers
  name                = "ctrl-public-ip-${count.index + 1}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  allocation_method = "Dynamic"
  domain_name_label = "${var.controller_name}${count.index + 1}"
}

resource "azurerm_network_interface" "ctrl-mgmnt-nics" {
  count                       = var.controllers
  name                        = "ctrl-mgmnt-nic-${count.index + 1}"
  location                    = azurerm_resource_group.resgroup.location
  resource_group_name         = azurerm_resource_group.resgroup.name
  internal_dns_name_label     = "${var.controller_name}${count.index + 1}"

  ip_configuration {
    name                          = "ctrl-mgmnt-nic-ip-${count.index + 1}"
    subnet_id                     = azurerm_subnet.management.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    //private_ip_address            = "10.0.0.${format("%02d", count.index + 4)}"
    public_ip_address_id          = azurerm_public_ip.ctrl-public-ips[count.index].id
  }
}

resource "azurerm_network_interface" "ctrl-private-nics" {
  count                       = var.controllers
  name                        = "ctrl-private-nic-${count.index + 1}"
  location                    = azurerm_resource_group.resgroup.location
  resource_group_name         = azurerm_resource_group.resgroup.name
  internal_dns_name_label     = "${var.controller_name}${count.index + 1}s"

  ip_configuration {
    name                          = "ctrl-private-nic-ip-${count.index + 1}"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ctrl-vm" {
  count                 = var.controllers
  name                  = "${var.controller_name}${count.index + 1}"
  computer_name         = "${var.controller_name}${count.index + 1}"
  custom_data           = base64encode( 
    templatefile( "controller_custom_data.sh", { 
      "hostname": "${var.controller_name}${count.index + 1}"
      "domain": "${var.location}.cloudapp.azure.com"
      "internal_domain": var.use_internal_domain 
      "ipaddr": azurerm_network_interface.ctrl-mgmnt-nics[count.index].private_ip_address
      "username": var.admin_user
      "controller_admin_user": var.controller_admin_user
      "controller_admin_pass": var.controller_admin_pass
      "controller_token": var.controller_token
    })
  )
  location              = azurerm_resource_group.resgroup.location
  resource_group_name   = azurerm_resource_group.resgroup.name
  network_interface_ids = [
    azurerm_network_interface.ctrl-mgmnt-nics[count.index].id,
    azurerm_network_interface.ctrl-private-nics[count.index].id
  ]
  size                  = var.controller_size
  admin_username        = var.admin_user
  source_image_id       = data.azurerm_image.ctrl-img.0.id

  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.admin_ssh_key)
  } 

  os_disk {
    name              = "ctrl-vhd-${count.index + 1}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
}

