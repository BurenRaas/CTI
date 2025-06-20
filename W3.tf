terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.24.0"
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


/////


resource "azurerm_application_security_group" "SSC-WEB-ASG" {
  name                = "SSC-WEB-ASG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_application_security_group" "SSC-APP-ASG" {
  name                = "SSC-APP-ASG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_application_security_group" "SSC-DB-ASG" {
  name                = "SSC-DB-ASG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "SSC-WEB-NSG" {
  name                = "SSC-WEB-ASG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_application_security_group_ids = [azurerm_application_security_group.SSC-WEB-ASG.id]
  }

  security_rule {
    name                       = "Deny-Web-to-DB"
    priority                   = 400
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_application_security_group_ids = [azurerm_application_security_group.SSC-WEB-ASG.id]
    destination_application_security_group_ids = [azurerm_application_security_group.SSC-DB-ASG.id]
    source_port_range          = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_network_security_group" "SSC-APP-NSG" {
  name                = "SSC-APP-NSG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-Web-to-App"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_application_security_group_ids = [azurerm_application_security_group.SSC-WEB-ASG.id]
    destination_application_security_group_ids = [azurerm_application_security_group.SSC-APP-ASG.id]
    source_port_range          = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "Allow-App-to-DB"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_application_security_group_ids = [azurerm_application_security_group.SSC-APP-ASG.id]
    destination_application_security_group_ids = [azurerm_application_security_group.SSC-DB-ASG.id]
    source_port_range          = "*"
    destination_port_range     = "1433"
  }
}
