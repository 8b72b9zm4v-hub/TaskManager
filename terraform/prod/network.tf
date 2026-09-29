# Network
resource "azurerm_virtual_network" "vNet" {
  name                = "private-network"
  location            = data.azurerm_resource_group.TaskManagerResourceGroup.location
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
  # Azure demande un /28 pour postgre soit 16 adresses et /27 pour container apps soit 32 adresses -> 48 adresses au total -> 64 adresses -> 6 bits -> /26 
  address_space = ["10.0.0.0/26"]
}

resource "azurerm_subnet" "computesubnet" {
  name                 = "computesubnet"
  resource_group_name  = data.azurerm_resource_group.TaskManagerResourceGroup.name
  virtual_network_name = azurerm_virtual_network.vNet.name
  address_prefixes     = ["10.0.0.0/27"]
  delegation {
    name = "envdelegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "postgredelegation" {
  name                 = "storagesubnet"
  resource_group_name  = data.azurerm_resource_group.TaskManagerResourceGroup.name
  virtual_network_name = azurerm_virtual_network.vNet.name
  address_prefixes     = ["10.0.0.32/28"]
  delegation {
    name = "postgredelegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
# Dns
resource "azurerm_private_dns_zone" "dnszone" {
  name                = "taskmanager.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtualnetworklink" {
  name                = "taskmanager-postgresql-vnet-link"
  private_dns_zone_id = azurerm_private_dns_zone.dnszone.id
  virtual_network_id  = azurerm_virtual_network.vNet.id
}