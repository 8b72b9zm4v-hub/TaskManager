# static web apps 
resource "azurerm_static_web_app" "static_web_app" {
  name                = "frontend"
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
  location            = "eastus2"
  sku_tier            = "Free"
  sku_size            = "Free"
}
