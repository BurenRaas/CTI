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
  name     = "s1190828_storage_demo"
  location = "northeurope"
}
  
////

#Hot blob storage
resource "azurerm_storage_account" "website" {
  name                     = "webstorages1190828"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  access_tier              = "Hot"
  account_replication_type = "LRS"


  static_website {
    index_document     = "index.html"
    error_404_document = "404error.html"
  }
}

#Cold blob storage
resource "azurerm_storage_account" "pdfstorage" {
  name                     = "pdfstorageacct01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  access_tier              = "Cold"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "pdfs" {
  name                  = "pdf-files"
  storage_account_name  = azurerm_storage_account.pdfstorage.name
  container_access_type = "private"
}

#SQL storage
resource "azurerm_mssql_server" "sql" {
  name                         = "sqlservers1190828"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Welkom01!!"
}

resource "azurerm_mssql_database" "db" {
  name         = "db"
  server_id    = azurerm_mssql_server.sql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 1
  sku_name     = "Basic"
}


#Tablestorage
resource "azurerm_storage_account" "smslogs" {
  name                     = "smslogstorage01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_table" "sms_logs" {
  name                 = "smslogs"
  storage_account_name = azurerm_storage_account.smslogs.name
}
