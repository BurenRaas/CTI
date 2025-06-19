terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "7c2cf771-1067-4e56-9047-4a218905ddaf"
}


data "azurerm_resource_group" "rg" {
  name = "s1190828"
}

#SSC-SUBNET
resource "azurerm_virtual_network" "SSC-VNET" {
  name                = "IAC-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

#SSC-WEB



resource "azurerm_subnet" "SSC-WEB-SUBNET" {
  name                 = "SSC-WEB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_network_interface" "SSC-WEB-WEB" {
  count               = 1
  name                = "SSC-WEB-NIC-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SSC-WEB-SUBNET.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "SSC-WEB-VM" {
  count                           = 1
  name                            = "SSC-WEB-VM${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  admin_username                  = "student"
  admin_password                  = "Welkom01!!"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.SSC-WEB-WEB[count.index].id]

  admin_ssh_key {
    username   = "student"
    public_key = file("~/.ssh/iac.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

}

///////////


#SSC-APP

resource "azurerm_subnet" "SSC-APP-SUBNET" {
  name                 = "SSC-APP"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_network_interface" "SSC-APP-NIC" {
  count               = 1
  name                = "SSC-APP-NIC-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SSC-APP-SUBNET.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "SSC-APP-VM" {
  count                           = 1
  name                            = "SSC-APP-VM${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  admin_username                  = "student"
  admin_password                  = "Welkom01!!"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.SSC-APP-NIC[count.index].id]

  admin_ssh_key {
    username   = "student"
    public_key = file("~/.ssh/iac.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

}

///////////


#SSC-DB

resource "azurerm_subnet" "SSC-DB-SUBNET" {
  name                 = "SSC-DB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_network_interface" "SSC-DB-NIC" {
  count               = 1
  name                = "SSC-DB-NIC-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SSC-DB-SUBNET.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "SSC-DB-VM" {
  count                           = 1
  name                            = "SSC-DB-VM${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  admin_username                  = "student"
  admin_password                  = "Welkom01!!"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.SSC-DB-NIC[count.index].id]

  admin_ssh_key {
    username   = "student"
    public_key = file("~/.ssh/iac.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

}

///////////




