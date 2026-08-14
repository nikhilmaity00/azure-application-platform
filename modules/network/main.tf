resource "azurerm_virtual_network" "VNET" {
  name                = var.vnet
  resource_group_name = var.rg
  location            = var.location
  address_space       = [var.cidr]
}

resource "azurerm_subnet" "SN" {
  for_each             = var.subnets
  address_prefixes     = [each.value]
  virtual_network_name = azurerm_virtual_network.VNET.name
  name                 = "subnet-${each.key}"
  resource_group_name  = var.rg
}

resource "azurerm_network_security_group" "NSG" {
  location            = var.location
  name                = var.nsg
  resource_group_name = var.rg
}

resource "azurerm_network_security_rule" "NSR" {
  for_each                    = var.nsg_rules
  direction                   = "Inbound"
  priority                    = each.value.priority
  network_security_group_name = azurerm_network_security_group.NSG.name
  name                        = "allow-${each.key}"
  protocol                    = "Tcp"
  resource_group_name         = var.rg
  access                      = "Allow"
  source_address_prefix       = each.value.source
  source_port_range = "*"
  destination_address_prefix  = "*"
  destination_port_range      = each.value.port
}

resource "azurerm_subnet_network_security_group_association" "SNSGA" {
  network_security_group_id = azurerm_network_security_group.NSG.id
  subnet_id                 = azurerm_subnet.SN["web"].id
}