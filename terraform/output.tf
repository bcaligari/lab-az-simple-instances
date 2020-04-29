output "admin" {
  value = {
    username        = var.admin_user
    ssh_private_key = var.ssh_private_key
    ssh_public_key  = var.ssh_public_key
  }
}

output "azure" {
  value = {
    resource_group = var.resource_group_name
    location       = var.location
  }
}

output "hosts" {
  value = {
    hostname   = azurerm_linux_virtual_machine.adhoc[*].computer_name
    public_ip  = azurerm_public_ip.adhoc[*].ip_address
    private_ip = azurerm_network_interface.adhoc[*].private_ip_address
  }
}
