terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG" {
  name     = var.rg
  location = var.location
}

resource "azurerm_network_interface" "NI" {
  name                = var.ni
  location            = var.location
  resource_group_name = var.rg
  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.network.subnet_ids["web"]
    public_ip_address_id          = azurerm_public_ip.PIP.id
  }
}

resource "azurerm_linux_virtual_machine" "VM1" {
  name                  = "${var.vm}1"
  location              = var.location
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.NI.id]
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_public_ip" "PIP" {
  name                = "pip"
  location            = var.location
  allocation_method   = "Static"
  resource_group_name = var.rg
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "KV" {
  location                   = var.location
  name                       = var.kv
  resource_group_name        = var.rg
  rbac_authorization_enabled = true
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

resource "azurerm_key_vault_secret" "KVSecret" {
  name = "kvs"
  value = var.app_secret
  key_vault_id = azurerm_key_vault.KV.id
}

# resource "azurerm_role_assignment" "KVSU" {
#   scope                = azurerm_key_vault.KV.id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = azurerm_linux_virtual_machine.VM1.identity[0].principal_id
# }

module "network" {
  source    = "./modules/network"
  subnets   = var.subnets
  rg        = var.rg
  location  = var.location
  cidr      = var.cidr
  nsg       = var.nsg
  vnet      = var.vnet
  nsg_rules = var.nsg_rules
}

