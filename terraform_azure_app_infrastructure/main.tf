terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.78.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "codility"
  location = "uksouth"
}

# 1. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 2. Subnets
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 3. Network Interfaces
resource "azurerm_network_interface" "app_vm_interface" {
  name                = "app_vm_interface"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "app_vm_interface"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "db_vm_interface" {
  name                = "db_vm_interface"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "db_vm_interface"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 4. Virtual Machines
resource "azurerm_linux_virtual_machine" "app-vm" {
  name                            = "app-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "adminPa$$word"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.app_vm_interface.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "db-vm" {
  name                            = "db-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "adminPa$$word"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.db_vm_interface.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

# 5. Public IPs
resource "azurerm_public_ip" "public_ip_bastion" {
  name                = "public_ip_bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "public_ip_lb" {
  name                = "public_ip_lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 6. Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  ip_configuration {
    name                 = "bastion_config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.public_ip_bastion.id
  }
}

# 7. Load Balancer
resource "azurerm_lb" "app_lb" {
  name                = "app_lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "app_lb_config"
    public_ip_address_id = azurerm_public_ip.public_ip_lb.id
  }
}

# 8. Load Balancer Backend Address Pool
resource "azurerm_lb_backend_address_pool" "app_lb_backend_pool" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "app_lb_backend_pool"
}

# 9. Network Interface Backend Address Pool Association
resource "azurerm_network_interface_backend_address_pool_association" "app_lb_association" {
  network_interface_id    = azurerm_network_interface.app_vm_interface.id
  ip_configuration_name   = "app_vm_interface"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_lb_backend_pool.id
}

# 10. Load Balancer Rules
resource "azurerm_lb_rule" "app_tcp_80" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "app_tcp_80"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "app_lb_config"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_lb_backend_pool.id]
}

resource "azurerm_lb_rule" "app_tcp_443" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "app_tcp_443"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "app_lb_config"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_lb_backend_pool.id]
}
