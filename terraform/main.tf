provider "azurerm" {
  version = ">= 2.7.0"
  features {}
}

# All resources will go into this resource group
resource "azurerm_resource_group" "adhoc_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# A virtual network will host all subnets
resource "azurerm_virtual_network" "adhoc_vnet" {
  name                = "vnet-${var.default_vnet_suffix}"
  resource_group_name = azurerm_resource_group.adhoc_rg.name
  location            = azurerm_resource_group.adhoc_rg.location
  address_space       = [var.default_vnet_address_space]
  tags                = azurerm_resource_group.adhoc_rg.tags
}

# Only one subnet needed in this case
resource "azurerm_subnet" "adhoc_snet" {
  name                 = "snet-${var.default_snet_suffix}"
  resource_group_name  = azurerm_resource_group.adhoc_rg.name
  virtual_network_name = azurerm_virtual_network.adhoc_vnet.name
  address_prefixes     = [var.default_snet_address_prefix]
}

# Basic nsg for linux hosts
resource "azurerm_network_security_group" "adhoc_nsg" {
  name                = "nsg-${azurerm_resource_group.adhoc_rg.name}"
  resource_group_name = azurerm_resource_group.adhoc_rg.name
  location            = azurerm_resource_group.adhoc_rg.location
  tags                = azurerm_resource_group.adhoc_rg.tags
}

# Security rule to allow SSH
resource "azurerm_network_security_rule" "adhoc_secrule_ssh" {
  name                        = "nsg-rule-${azurerm_resource_group.adhoc_rg.name}-ssh"
  resource_group_name         = azurerm_resource_group.adhoc_rg.name
  network_security_group_name = azurerm_network_security_group.adhoc_nsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# nodes will need a public IP
resource "azurerm_public_ip" "adhoc_pip" {
  count               = var.instances
  name                = "pip-${var.hostname}${count.index}"
  resource_group_name = azurerm_resource_group.adhoc_rg.name
  location            = azurerm_resource_group.adhoc_rg.location
  allocation_method   = "Static"
  tags                = azurerm_resource_group.adhoc_rg.tags
}

# Only a single NIC is required for these nodes
resource "azurerm_network_interface" "adhoc_nic" {
  count               = var.instances
  name                = "nic-${var.hostname}${count.index}"
  resource_group_name = azurerm_resource_group.adhoc_rg.name
  location            = azurerm_resource_group.adhoc_rg.location
  tags                = azurerm_resource_group.adhoc_rg.tags

  ip_configuration {
    name                          = "eth0"
    subnet_id                     = azurerm_subnet.adhoc_snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.adhoc_pip[count.index].id
  }
}

# The network security group must be associated with the nic itself
resource "azurerm_network_interface_security_group_association" "adhoc" {
  count                     = var.instances
  network_interface_id      = azurerm_network_interface.adhoc_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.adhoc_nsg.id
}

# The actual adhoc vm resource
resource "azurerm_linux_virtual_machine" "adhoc_vm" {
  count                           = var.instances
  name                            = "vm-${var.hostname}${count.index}"
  resource_group_name             = azurerm_resource_group.adhoc_rg.name
  location                        = azurerm_resource_group.adhoc_rg.location
  network_interface_ids           = [azurerm_network_interface.adhoc_nic[count.index].id]
  size                            = var.vm_size
  computer_name                   = "${var.hostname}-${count.index}"
  admin_username                  = var.admin_user
  disable_password_authentication = true

  source_image_reference {
    publisher = var.vm_image["publisher"]
    offer     = var.vm_image["offer"]
    sku       = var.vm_image["sku"]
    version   = var.vm_image["version"]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.ssh_public_key)
  }

  tags = azurerm_resource_group.adhoc_rg.tags
}
