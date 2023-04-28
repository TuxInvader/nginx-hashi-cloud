

output "k8s_id" {
  value = azurerm_kubernetes_cluster.config[*].id
}

output "k8s_host" {
  value = azurerm_kubernetes_cluster.config[*].kube_config.0.host
  sensitive = true
}

output "nginx_public_ips" {
  value = azurerm_public_ip.nginx-public-ips
}

output "ctrl_public_ips" {
  value = azurerm_public_ip.ctrl-public-ips
}

output "nim_public_ips" {
  value = azurerm_public_ip.nim-public-ips
}
 
