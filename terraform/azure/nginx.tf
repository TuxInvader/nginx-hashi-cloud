data "azurerm_image" "nginx-img" {
  name                = var.nginx_image
  resource_group_name = var.image_rg
  count               = var.nginxs
}

resource "azurerm_public_ip" "nginx-public-ips" {
  count               = var.nginxs
  name                = "nginx-public-ip-${count.index + 1}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  allocation_method = "Dynamic"
  domain_name_label = "${var.nginx_name}${count.index + 1}"
}

resource "azurerm_network_interface" "nginx-public-nics" {
  count               = var.nginxs
  name                = "nginx-public-nic-${count.index + 1}"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
  internal_dns_name_label     = "${var.nginx_name}${count.index + 1}s"

  ip_configuration {
    name                            = "nginx-public-nic-ip-${count.index + 1}"
    subnet_id                       = azurerm_subnet.public.id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = azurerm_public_ip.nginx-public-ips[count.index].id
  }
}

resource "azurerm_network_interface" "nginx-private-nics" {
  count                       = var.nginxs
  name                        = "nginx-private-nic-${count.index + 1}"
  location                    = azurerm_resource_group.resgroup.location
  resource_group_name         = azurerm_resource_group.resgroup.name
  internal_dns_name_label     = "${var.nginx_name}${count.index + 1}"

  ip_configuration {
    name                            = "nginx-private-nic-ip-${count.index + 1}"
    subnet_id                       = azurerm_subnet.private.id
    private_ip_address_allocation   = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "nginx-vm" {
  count                 = var.nginxs
  name                  = "${var.nginx_name}${count.index + 1}"
  computer_name         = "${var.nginx_name}${count.index + 1}"
  custom_data           = base64encode( 
    templatefile( "nginx_custom_data.sh", { 
      "hostname": "${var.nginx_name}${count.index + 1}"
      "domain": "${var.location}.cloudapp.azure.com"
      "internal_domain": var.use_internal_domain 
      "ipaddr": azurerm_network_interface.nginx-private-nics[count.index].private_ip_address
      "username": var.admin_user
      "controller_name": "${var.controller_name}1"
      "controller_admin_user": var.controller_admin_user
      "controller_admin_pass": var.controller_admin_pass
      "controller_token": var.controller_token
      "nginx_location": var.nginx_location
    })
  )
  location              = azurerm_resource_group.resgroup.location
  resource_group_name   = azurerm_resource_group.resgroup.name
  network_interface_ids = [
    azurerm_network_interface.nginx-public-nics[count.index].id,
    azurerm_network_interface.nginx-private-nics[count.index].id
  ]
  size                  = var.nginx_size
  admin_username        = var.admin_user
  source_image_id       = data.azurerm_image.nginx-img.0.id

  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.admin_ssh_key)
  } 

  os_disk {
    name              = "nginx-vhd-${count.index + 1}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}
