# Configure Azure Provider
provider "azurerm" {
  features {}
}

# Define Variables (replace with your details)
variable "resource_group_name" {
  type = string
  default = "terraform-test-rg"
}
variable "location" {
  type = string
  default = "East US"
}
variable "vnet_name" {
  type = string
  default =  "terraform_vnet"
}
variable "subnet_name" {
  type = string
  default = "terraform_subnet"
}
variable "admin_username" {
  type = string
  default = "username"
}
variable "admin_password" {
  type = string
  sensitive = true
  default = "password"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name = var.resource_group_name
  location = var.location 
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["192.168.0.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                        = var.subnet_name
  resource_group_name         = azurerm_resource_group.rg.name
  virtual_network_name       = azurerm_virtual_network.vnet.name
  address_prefixes           = ["192.168.0.64/26"]
}


# Create Network Interface
resource "azurerm_network_interface" "nic" {
  name                = format("%s-nic", var.vm_name)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                    = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Define VM Name (optional, replace with desired name)
variable "vm_name" {
  type = string
  default = "Terraform-ubuntu-vm"
}

# Create Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size              = "Standard_D2s_v3"
  admin_username = var.admin_username
  admin_password = var.admin_password
  disable_password_authentication = false

  # OS Configuration
  
 os_disk {
    name                 = "Terraform-ubuntu-vm"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }  
  
  source_image_reference {
    offer = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku = "20_04-lts-gen2"
    version = "20.04.202302090"
  }
  	
}