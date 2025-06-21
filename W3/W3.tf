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

////

#SSC-VNET
resource "azurerm_virtual_network" "SSC-VNET" {
  name                = "SSC-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

#SSC-WEB-layer

resource "azurerm_subnet" "SSC-WEB-SUBNET" {
  name                 = "SSC-WEB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_subnet_network_security_group_association" "SSC-WEB-ASSOC" {
  subnet_id                 = azurerm_subnet.SSC-WEB-SUBNET.id
  network_security_group_id = azurerm_network_security_group.SSC-WEB-NSG.id
}

#VM NIC
resource "azurerm_network_interface" "SSC-WEB-NIC" {
  count               = 1
  name                = "SSC-WEB-NIC-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                            = "internal"
    subnet_id                       = azurerm_subnet.SSC-WEB-SUBNET.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
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

  network_interface_ids = [azurerm_network_interface.SSC-WEB-NIC[count.index].id]

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

#SSC-APP-layer

resource "azurerm_subnet" "SSC-APP-SUBNET" {
  name                 = "SSC-APP"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}


#VM NIC
resource "azurerm_network_interface" "SSC-APP-NIC" {
  count               = 1
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
  port                = 443
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
  count                   = 1
  network_interface_id    = azurerm_network_interface.SSC-APP-NIC[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_pool.id
}


///
#SSC-DB-layer

resource "azurerm_subnet" "SSC-DB-SUBNET" {
  name                 = "SSC-DB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.3.0/24"]
}


resource "azurerm_subnet_network_security_group_association" "SSC-DB-ASSOC" {
  subnet_id                 = azurerm_subnet.SSC-DB-SUBNET.id
  network_security_group_id = azurerm_network_security_group.SSC-APP-NSG.id
}

#VM NIC
resource "azurerm_network_interface" "SSC-DB-NIC" {
  count               = 1
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
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "DB-frontend"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.DB_pool.id]
  probe_id = azurerm_lb_probe.db_http_probe.id
}

# Koppel DB-NIC aan backend pool
resource "azurerm_network_interface_backend_address_pool_association" "DB_nic_lb" {
  count                   = 1
  network_interface_id    = azurerm_network_interface.SSC-DB-NIC[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.DB_pool.id
}



/////

#ASG en NSG regels

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
  name                = "SSC-WEB-NSG"
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
    priority                   = 100
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
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_application_security_group_ids = [azurerm_application_security_group.SSC-APP-ASG.id]
    destination_application_security_group_ids = [azurerm_application_security_group.SSC-DB-ASG.id]
    source_port_range          = "*"
    destination_port_range     = "1433"
  }
}

resource "azurerm_public_ip" "SSC-AGW-PUBIP" {
  name                = "SSC-AGW-PUBIP"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "SSC-AGW-SUBNET" {
  name                 = "SSC-AGW-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.SSC-VNET.name
  address_prefixes     = ["10.0.100.0/24"]
}

resource "azurerm_application_gateway" "SSC-WAF" {
  name                = "SSC-WAF"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.SSC-AGW-SUBNET.id
  }

  frontend_port {
    name = "frontend-port"
    port = 443
  }

    frontend_port {
    name = "frontend-port-http"
    port = 80
  }


  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.SSC-AGW-PUBIP.id
  }

  backend_address_pool {
    name         = "web-backend-pool"
    ip_addresses = ["10.0.1.4"]
  }

  backend_http_settings {
    name                  = "web-http-settings"
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    pick_host_name_from_backend_address = false
    request_timeout      = 20
  }

  http_listener {
    name                           = "appgw-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Https"
    ssl_certificate_name           = "ssl-cert"
  }
    http_listener {
    name                           = "appgw-listener-http"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port-http"
    protocol                       = "Http"
  }


  ssl_certificate {
    name     = "ssl-cert"
    data     = filebase64("~/CTI/CTI automatiseringsvraagstukken/W3/ssc-cert.pfx")
  }

  url_path_map {
    name                               = "path-map"
    default_backend_address_pool_name  = "web-backend-pool"
    default_backend_http_settings_name = "web-http-settings"

    path_rule {
      name                        = "root-path-rule"
      paths                       = ["/*"]
      backend_address_pool_name   = "web-backend-pool"
      backend_http_settings_name  = "web-http-settings"
    }
  }

  request_routing_rule {
    name                       = "web-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-listener"
    backend_address_pool_name  = "web-backend-pool"
    backend_http_settings_name = "web-http-settings"
    priority                     = 100
  }

    request_routing_rule {
      name                         = "http-redirect-rule"
      rule_type                    = "Basic"
      http_listener_name           = "appgw-listener-http"
      redirect_configuration_name  = "http-to-https-redirect"
      priority                     = 110
}

redirect_configuration {
  name                  = "http-to-https-redirect"
  redirect_type         = "Permanent"
  target_listener_name  = "appgw-listener"
  include_path          = true
  include_query_string  = true
}

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}

