output "vnet_id" {
  value = module.network.vnet_id
}

output "web_subnet_id" {
  value = module.network.subnet_ids["web"]
}

output "vm_private_ip" {
  value = azurerm_network_interface.NI.private_ip_address
}

output "vm_public_ip" {
  value = azurerm_public_ip.PIP.ip_address
}