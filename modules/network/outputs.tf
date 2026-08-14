output "vnet_id" {
  value = azurerm_virtual_network.VNET.id
}

output "subnet_ids" {
  value = {
    for name, subnet in azurerm_subnet.SN :
    name => subnet.id
  }
}