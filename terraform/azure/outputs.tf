 # outputs

 output "nginx_public_ips" {
   value = azurerm_public_ip.nginx-public-ips
 }


 output "ctrl_public_ips" {
   value = azurerm_public_ip.ctrl-public-ips
 }

 output "ctrl_private_ips" {
   value = azurerm_network_interface.ctrl-mgmnt-nics
 }
 