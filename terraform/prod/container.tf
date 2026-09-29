
resource "azurerm_container_app_environment" "container_app_env" {
  name                       = "containerapp-env"
  location                   = data.azurerm_resource_group.TaskManagerResourceGroup.location
  resource_group_name        = data.azurerm_resource_group.TaskManagerResourceGroup.name
  infrastructure_subnet_id   = azurerm_subnet.computesubnet.id
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs_analytics.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}
# CONTAINER APPS

resource "azurerm_container_app" "container_app" {
  name                         = "backend"
  container_app_environment_id = azurerm_container_app_environment.container_app_env.id
  resource_group_name          = data.azurerm_resource_group.TaskManagerResourceGroup.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type = "UserAssigned"
    identity_ids = [
      data.terraform_remote_state.bootstrap.outputs.backend_runtime_identity_id
    ]
  }

  registry {
    server   = data.terraform_remote_state.bootstrap.outputs.acr_login_server
    identity = data.terraform_remote_state.bootstrap.outputs.backend_runtime_identity_id
  }

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
  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }
}