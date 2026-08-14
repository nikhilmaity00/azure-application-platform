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

variable "nsg_rules" {
  type = map(object({
    priority = number
    port     = string
    source   = string
  }))
}