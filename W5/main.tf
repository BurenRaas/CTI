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
  name = "s1190828_w5"
}

#SSC-VNET
resource "azurerm_virtual_network" "SSC-VNET" {
  name                = "SSC-vnet"
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

#ASG
resource "azurerm_application_security_group" "SSC-WEB-ASG" {
  name                = "SSC-WEB-ASG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

#NSG
resource "azurerm_network_security_group" "SSC-WEB-NSG" {
  name                = "SSC-WEB-NSG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "SSC-WEB-ASSOC" {
  subnet_id                 = azurerm_subnet.SSC-WEB-SUBNET.id
  network_security_group_id = azurerm_network_security_group.SSC-WEB-NSG.id
}

#VM NIC
resource "azurerm_network_interface" "SSC-WEB-NIC" {
  count               = 2
  name                = "SSC-WEB-NIC-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                            = "internal"
    subnet_id                       = azurerm_subnet.SSC-WEB-SUBNET.id
    private_ip_address_allocation   = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "SSC-WEB-VM" {
  count                           = 2
  name                            = "SSC-WEB-VM${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  admin_username                  = "student"
  admin_password                  = "Welkom01!!"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.SSC-WEB-NIC[count.index].id]

    availability_set_id = azurerm_availability_set.SSC-WEB-AV.id


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




//////

#SSC-APP

resource "azurerm_subnet" "SSC-APP-SUBNET" {
  name                 = "SSC-APP"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}

#ASG
resource "azurerm_application_security_group" "SSC-APP-ASG" {
  name                = "SSC-APP-ASG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

#NSG
resource "azurerm_network_security_group" "SSC-APP-NSG" {
  name                = "SSC-APP-NSG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "SSC-APP-ASSOC" {
  subnet_id                 = azurerm_subnet.SSC-APP-SUBNET.id
  network_security_group_id = azurerm_network_security_group.SSC-APP-NSG.id
}

#VM NIC
resource "azurerm_network_interface" "SSC-APP-NIC" {
  count               = 0
  name                = "SSC-APP-NIC${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                            = "internal"
    subnet_id                       = azurerm_subnet.SSC-APP-SUBNET.id
    private_ip_address_allocation   = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "SSC-APP-VM" {
  count                           = 0
  name                            = "SSC-APP-VM${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  admin_username                  = "student"
  admin_password                  = "Welkom01!!"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.SSC-APP-NIC[count.index].id]

      availability_set_id = azurerm_availability_set.SSC-APP-AV.id

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


/////

#SSC WEB to APP loadbalancer

resource "azurerm_lb" "SSC-APP-LB" {
  name                = "app-internal-lb"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "app-frontend"
    subnet_id                     = azurerm_subnet.SSC-WEB-SUBNET.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.100"
  }
}

resource "azurerm_lb_backend_address_pool" "app_pool" {
  name                = "app-backend-pool"
  loadbalancer_id     = azurerm_lb.SSC-APP-LB.id
}

resource "azurerm_lb_probe" "http_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.SSC-APP-LB.id
  protocol            = "Tcp"
  port                = 8080
}

resource "azurerm_lb_rule" "SSC-APP-LB_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.SSC-APP-LB.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "app-frontend"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.app_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# Koppel app-NIC aan backend pool
resource "azurerm_network_interface_backend_address_pool_association" "app_nic_lb" {
  count                   = 0
  network_interface_id    = azurerm_network_interface.SSC-APP-NIC[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_pool.id
}


///
#SSC-DB

resource "azurerm_subnet" "SSC-DB-SUBNET" {
  name                 = "SSC-DB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.3.0/24"]
}

#ASG
resource "azurerm_application_security_group" "SSC-DB-ASG" {
  name                = "SSC-DB-ASG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

#NSG
resource "azurerm_network_security_group" "SSC-DB-NSG" {
  name                = "SSC-DB-NSG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "SSC-DB-ASSOC" {
  subnet_id                 = azurerm_subnet.SSC-DB-SUBNET.id
  network_security_group_id = azurerm_network_security_group.SSC-DB-NSG.id
}

#VM NIC
resource "azurerm_network_interface" "SSC-DB-NIC" {
  count               = 0
  name                = "SSC-DB-NIC${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                            = "internal"
    subnet_id                       = azurerm_subnet.SSC-DB-SUBNET.id
    private_ip_address_allocation   = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "SSC-DB-VM" {
  count                           = 0
  name                            = "SSC-DB-VM${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  admin_username                  = "student"
  admin_password                  = "Welkom01!!"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.SSC-DB-NIC[count.index].id]

      availability_set_id = azurerm_availability_set.SSC-DB-AV.id

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
#SSC WEB to DB loadbalancer

resource "azurerm_lb" "SSC-DB-LB" {
  name                = "DB-internal-lb"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "DB-frontend"
    subnet_id                     = azurerm_subnet.SSC-APP-SUBNET.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.100"
  }
}

resource "azurerm_lb_backend_address_pool" "DB_pool" {
  name                = "DB-backend-pool"
  loadbalancer_id     = azurerm_lb.SSC-DB-LB.id
}

resource "azurerm_lb_probe" "db_http_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.SSC-DB-LB.id
  protocol            = "Tcp"
  port                = 8080
}

resource "azurerm_lb_rule" "SSC-DB-LB_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.SSC-DB-LB.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "DB-frontend"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.DB_pool.id]
  probe_id = azurerm_lb_probe.db_http_probe.id
}

# Koppel DB-NIC aan backend pool
resource "azurerm_network_interface_backend_address_pool_association" "DB_nic_lb" {
  count                   = 0
  network_interface_id    = azurerm_network_interface.SSC-DB-NIC[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.DB_pool.id
}

///////

#AGW

# Public IP for AGW
resource "azurerm_public_ip" "SSC-AGW-PUBIP" {
  name                = "agw-public-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Subnet for Application Gateway (must be dedicated!)
resource "azurerm_subnet" "SSC-AGW-SUBNET" {
  name                 = "agw-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.100.0/24"]
}



# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.SSC-VNET.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.SSC-VNET.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.SSC-VNET.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.SSC-VNET.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.SSC-VNET.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.SSC-VNET.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.SSC-VNET.name}-rdrcfg"
}


resource "azurerm_application_gateway" "SSC-AGW" {
  name                = "SSC-AGW"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.SSC-AGW-SUBNET.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
   name                 = local.frontend_ip_configuration_name
   public_ip_address_id = azurerm_public_ip.SSC-AGW-PUBIP.id
 }

  backend_address_pool {
  name = local.backend_address_pool_name
}

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

/////

#Availability sets
resource "azurerm_availability_set" "SSC-WEB-AV" {
  name                         = "SSC-WEB-AV"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags = {
    role = "web"
  }
}

resource "azurerm_availability_set" "SSC-APP-AV" {
  name                         = "SSC-APP-AV"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags = {
    role = "app"
  }
}

resource "azurerm_availability_set" "SSC-DB-AV" {
  name                         = "SSC-DB-AV"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags = {
    role = "db"
  }
}

/////

#Scaleset met een app service 

resource "azurerm_service_plan" "woz_plan" {
  name                = "asp-woz-taxaties"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  os_type = "Linux"
  sku_name = "S1"
}

resource "azurerm_app_service" "woz_app" {
  name                = "woz-taxatie-app"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_service_plan.woz_plan.id

  site_config {
    linux_fx_version = "NODE|18-lts"  # Voorbeeld
  }
}

resource "azurerm_monitor_autoscale_setting" "woz_autoscale" {
  name                = "woz-autoscale"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  target_resource_id  = azurerm_service_plan.woz_plan.id
  enabled             = true

  profile {
    name = "feb-maart-schaal"

    fixed_date {
      timezone = "W. Europe Standard Time"
      start    = "2025-02-01T00:00:00Z"
      end      = "2025-03-31T23:59:59Z"
    }

    capacity {
      minimum = "4"
      maximum = "4"
      default = "4"
    }
  }

  # Profiel buiten piekmaanden
  profile {
    name = "buiten-piek-maanden"
    capacity {
      minimum = "1"
      maximum = "1"
      default = "1"
    }
  }
}
