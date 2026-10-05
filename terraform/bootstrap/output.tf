# outputs
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "backend_runtime_identity_id" {
  value = azurerm_user_assigned_identity.acr_pull_container_app.id
}
output "bdd_group_members_id" {
  value = azuread_group.bdd_members.id
}
output "bdd_group_members_name" {
  value = azuread_group.bdd_members.display_name
}
output "postgresql_admin_group_name" {
  value = azuread_group.postgresql_admin_group_name.display_name
}
output "postgresql_admin_group_id" {
  value = azuread_group.postgresql_admin_group_name.object_id
}
output "bdd_admin_id" {
  value = azurerm_user_assigned_identity.bdd_admin.id
}
output "bdd_admin_client_id" {
  value = azurerm_user_assigned_identity.bdd_admin.client_id
}

output "bdd_user_id" {
  value = azurerm_user_assigned_identity.bdd_user.id
}

output "bdd_user_client_id" {
  value = azurerm_user_assigned_identity.bdd_user.client_id
}