variable "rg" {
  type = string
}

variable "location" {
  type = string
}

variable "subnets" {
  type = map(string)
}

variable "cidr" {
  type = string
}

variable "vnet" {
  type = string
}

variable "nsg" {
  type = string
}

variable "vm" {
  type = string
}

variable "ni" {
  type = string
}

variable "nsg_rules" {
  type = map(object({
    priority = number
    port     = string
    source   = string
  }))
}

variable "kv" {
  type = string
}

variable "app_secret" {
  type = string
  sensitive = true
}

variable "admin_ssh_public_key" {
  description = "SSH public key used to access the VM"
  type        = string
}