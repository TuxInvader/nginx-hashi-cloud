data "azurerm_image" "nim-img" {
  name                = var.nim_image
  resource_group_name = var.image_rg
  count               = var.nims
}

resource "azurerm_public_ip" "nim-public-ips" {
  count               = var.nims
  name                = "nim-public-ip-${count.index + 1}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  allocation_method = "Dynamic"
  domain_name_label = "${var.nim_name}${count.index + 1}"
}

resource "azurerm_network_interface" "nim-public-nics" {
  count               = var.nims
  name                = "nim-public-nic-${count.index + 1}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  internal_dns_name_label     = "${var.nim_name}${count.index + 1}s"

  ip_configuration {
    name                            = "nim-public-nic-ip-${count.index + 1}"
    subnet_id                       = azurerm_subnet.public.id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = azurerm_public_ip.nim-public-ips[count.index].id
  }
}

resource "azurerm_network_interface" "nim-private-nics" {
  count                       = var.nims
  name                        = "nim-private-nic-${count.index + 1}"
  location                    = azurerm_resource_group.resgroup.location
  resource_group_name         = azurerm_resource_group.resgroup.name
  internal_dns_name_label     = "${var.nim_name}${count.index + 1}"

  ip_configuration {
    name                            = "nim-private-nic-ip-${count.index + 1}"
    subnet_id                       = azurerm_subnet.private.id
    private_ip_address_allocation   = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "nim-vm" {
  count                 = var.nims
  name                  = "${var.nim_name}${count.index + 1}"
  computer_name         = "${var.nim_name}${count.index + 1}"
  custom_data           = base64encode( 
    templatefile( "nim_custom_data.sh", { 
      "hostname": "${var.nim_name}${count.index + 1}"
      "domain": "${var.location}.cloudapp.azure.com"
      "internal_domain": var.use_internal_domain 
      "ipaddr": azurerm_network_interface.nim-private-nics[count.index].private_ip_address
      "username": var.admin_user
      "manager_admin_user": var.manager_admin_user
      "manager_admin_pass": var.manager_admin_pass
      "manager_other_pass": var.manager_other_pass
      "manager_random_pass": random_password.admin.result
    })
  )
  location              = azurerm_resource_group.resgroup.location
  resource_group_name   = azurerm_resource_group.resgroup.name
  network_interface_ids = [
    azurerm_network_interface.nim-public-nics[count.index].id,
    azurerm_network_interface.nim-private-nics[count.index].id
  ]
  size                  = var.nim_size
  admin_username        = var.admin_user
  source_image_id       = data.azurerm_image.nim-img.0.id

  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.admin_ssh_key)
  } 

  os_disk {
    name              = "nim-vhd-${count.index + 1}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}
