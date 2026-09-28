data "azurerm_resource_group" "TaskManagerResourceGroup" {
  name = "TaskManager"
}

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

resource "azurerm_private_dns_zone" "dnszone" {
  name                = "taskmanager.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtualnetworklink" {
  name                = "taskmanager-postgresql-vnet-link"
  private_dns_zone_id = azurerm_private_dns_zone.dnszone.id
  virtual_network_id  = azurerm_virtual_network.vNet.id
}

# ACR
resource "azurerm_container_registry" "acr" {
  name                = "registrycontainer"
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
  location            = data.azurerm_resource_group.TaskManagerResourceGroup.location
  sku                 = "Standard"
}


# CONTAINER APPS
resource "azurerm_log_analytics_workspace" "logs_analytics" {
  name                = "logs"
  sku                 = "PerGB2018"
  location            = data.azurerm_resource_group.TaskManagerResourceGroup.location
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_container_app_environment" "container_app_env" {
  name                       = "containerapp-env"
  location                   = data.azurerm_resource_group.TaskManagerResourceGroup.location
  resource_group_name        = data.azurerm_resource_group.TaskManagerResourceGroup.name
  infrastructure_subnet_id   = azurerm_subnet.computesubnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs_analytics.id

  workload_profile {
    name                  = var.consumption_workload_profile
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "container_app" {
  name                         = "backend"
  container_app_environment_id = azurerm_container_app_environment.container_app_env.id
  resource_group_name          = data.azurerm_resource_group.TaskManagerResourceGroup.name
  revision_mode                = "Single"
  workload_profile_name        = var.consumption_workload_profile
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 3000
    traffic_weight {
      latest_revision = true
      percentage      = 100

    }
  }
  template {
    container {
      name   = "basictemplate"
      cpu    = 0.25
      memory = "0.5Gi"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
    }
  }
}

# static web apps 
resource "azurerm_static_web_app" "static_web_app" {
  name                = "frontend"
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
  location            = "westeurope""
  sku_tier            = "Free"
  sku_size            = "Free"

}

# PostgreDB
resource "azurerm_postgresql_flexible_server" "postgreSQL" {
  name                          = "postgresql-flexibleserver"
  resource_group_name           = data.azurerm_resource_group.TaskManagerResourceGroup.name
  location                      = data.azurerm_resource_group.TaskManagerResourceGroup.location
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgredelegation.id
  private_dns_zone_id           = azurerm_private_dns_zone.dnszone.id
  public_network_access_enabled = false
  administrator_login           = "psqladmin"
  administrator_password        = "@Fiat500"
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.virtualnetworklink]
}


# Vault
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                       = "taskmanager-kv"
  location                   = data.azurerm_resource_group.TaskManagerResourceGroup.location
  resource_group_name        = data.azurerm_resource_group.TaskManagerResourceGroup.name
  rbac_authorization_enabled = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
}

# storage tf state
