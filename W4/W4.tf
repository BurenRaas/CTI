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

resource "azurerm_resource_group" "rg" {
  name     = "s1190828"
  location = "westeurope"
}
  
////

resource "azurerm_storage_account" "storage" {
  name                     = "appstorageacct01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "files" {
  name                  = "pdf-docs"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "appcosmosdb01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "azurerm_mssql_server" "sql" {
  name                         = "sqlcrmserver01"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssword1234!"
}

resource "azurerm_mssql_database" "crm" {
  name                = "crmdb"
  server_id           = azurerm_mssql_server.sql.id
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  license_type        = "LicenseIncluded"
  max_size_gb         = 5
  sku_name            = "Basic"
}
