# PostgreDB
resource "azurerm_postgresql_flexible_server" "postgreSQL" {
  name                          = "postgresql-flexibleserver-${random_id.pg_suffix.hex}"
  resource_group_name           = data.azurerm_resource_group.TaskManagerResourceGroup.name
  location                      = data.azurerm_resource_group.TaskManagerResourceGroup.location
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgredelegation.id
  private_dns_zone_id           = azurerm_private_dns_zone.dnszone.id
  public_network_access_enabled = false
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.virtualnetworklink]
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "postgresql_admins" {
  server_name         = azurerm_postgresql_flexible_server.postgreSQL.name
  resource_group_name = data.azurerm_resource_group.TaskManagerResourceGroup.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  object_id      = data.terraform_remote_state.bootstrap.outputs.postgresql_admin_group_id
  principal_name = data.terraform_remote_state.bootstrap.outputs.postgresql_admin_group_name
  principal_type = "Group"
}