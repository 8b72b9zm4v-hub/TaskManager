data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
resource "azurerm_resource_group" "TaskManagerResourceGroup" {
  name     = "TaskManager"
  location = "France Central"
}

#  BDD
resource "azurerm_storage_account" "storage_account" {
  name                     = "taskmanager${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.TaskManagerResourceGroup.name
  location                 = azurerm_resource_group.TaskManagerResourceGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = "private"
}

# Acr
resource "azurerm_container_registry" "acr" {
  name                = "registrycontainer${random_id.acr_suffix.hex}"
  resource_group_name = azurerm_resource_group.TaskManagerResourceGroup.name
  location            = azurerm_resource_group.TaskManagerResourceGroup.location
  sku                 = "Standard"
}

