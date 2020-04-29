provider "azurerm" {
  version = ">= 2.7.0"
  features {}
}

# All resources will go into this resource group
resource "azurerm_resource_group" "adhoc" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# A virtual network will host all subnets
resource "azurerm_virtual_network" "adhoc" {
  name                = "vnet-${var.default_vnet_suffix}"
  resource_group_name = azurerm_resource_group.adhoc.name
  location            = azurerm_resource_group.adhoc.location
  address_space       = [var.default_vnet_address_space]
  tags                = azurerm_resource_group.adhoc.tags
}

# Only one subnet needed in this case
resource "azurerm_subnet" "adhoc" {
  name                 = "snet-${var.default_snet_suffix}"
  resource_group_name  = azurerm_resource_group.adhoc.name
  virtual_network_name = azurerm_virtual_network.adhoc.name
  address_prefix       = var.default_snet_address_prefix
}

# Basic nsg for linux hosts
resource "azurerm_network_security_group" "adhoc" {
  name                = "nsg-${azurerm_resource_group.adhoc.name}"
  resource_group_name = azurerm_resource_group.adhoc.name
  location            = azurerm_resource_group.adhoc.location

  security_rule {
    name                       = "nsg-basic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.adhoc.tags
}

# nodes will need a public IP
resource "azurerm_public_ip" "adhoc" {
  count               = var.instances
  name                = "pip-${var.hostname}${count.index}"
  resource_group_name = azurerm_resource_group.adhoc.name
  location            = azurerm_resource_group.adhoc.location
  allocation_method   = "Static"
  tags                = azurerm_resource_group.adhoc.tags
}

# Only a single NIC is required for these nodes
resource "azurerm_network_interface" "adhoc" {
  count               = var.instances
  name                = "nic-${var.hostname}${count.index}"
  resource_group_name = azurerm_resource_group.adhoc.name
  location            = azurerm_resource_group.adhoc.location
  tags                = azurerm_resource_group.adhoc.tags

  ip_configuration {
    name                          = "eth0"
    subnet_id                     = azurerm_subnet.adhoc.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.adhoc[count.index].id
  }
}

# The actual adhoc vm resource
resource "azurerm_linux_virtual_machine" "adhoc" {
  count                           = var.instances
  name                            = "vm-${var.hostname}${count.index}"
  resource_group_name             = azurerm_resource_group.adhoc.name
  location                        = azurerm_resource_group.adhoc.location
  network_interface_ids           = [azurerm_network_interface.adhoc[count.index].id]
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

  tags = azurerm_resource_group.adhoc.tags
}
