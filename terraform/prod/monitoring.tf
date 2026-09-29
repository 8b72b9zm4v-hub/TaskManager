resource "azurerm_log_analytics_workspace" "logs_analytics" {
  name                = "logs"
  sku                 = "PerGB2018"
  location            = data.azurerm_resource_group.TaskManagerResourceGroup.location
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
}