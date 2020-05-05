variable "resource_group_name" {
  description = "resource group for this cluster"
  type        = string
}

variable "tags" {
  description = "azure tags for cluster resources"
  type        = map(string)
}

variable "location" {
  description = "location"
  type        = string
}

variable "default_vnet_suffix" {
  description = "default vnet for this cluster"
  type        = string
  default     = "default"
}

variable "default_vnet_address_space" {
  description = "address space for vnet"
  type        = string
  default     = "172.16.0.0/16"
}

variable "default_snet_suffix" {
  description = "default subnet for this cluster"
  type        = string
  default     = "default"
}

variable "default_snet_address_prefix" {
  description = "address prefix for snet"
  type        = string
  default     = "172.16.0.0/24"
}

variable "admin_user" {
  description = "privileged (sudo) user for ssh login"
  type        = string
}

variable "ssh_private_key" {
  description = "ssh private key"
  type        = string
}

variable "ssh_public_key" {
  description = "ssh public key"
  type        = string
}

variable "instances" {
  description = "number of virtual machines to create"
  type        = number
  default     = 1
}

variable "hostname" {
  description = "hostname prefix for clientvm vm"
  type        = string
  default     = "node"
}

variable "vm_size" {
  description = "vm_size for clientvm vm"
  type        = string
}

variable "vm_image" {
  description = "storage image reference for clientvm vm"
  type        = map(string)
}

variable "tcp_ports" {
  description = "list of tcp ports to be opened"
  type        = list(string)
  default     = ["22"]
}

variable "udp_ports" {
  description = "list of udp ports to be opened"
  type        = list(string)
  default     = []
}
