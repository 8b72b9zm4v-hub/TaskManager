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
      data.terraform_remote_state.bootstrap.outputs.backend_runtime_identity_id,
      data.terraform_remote_state.bootstrap.outputs.bdd_user_id,
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
      env {
        name  = "AZURE_CLIENT_ID"
        value = data.terraform_remote_state.bootstrap.outputs.bdd_user_client_id
      }

      env {
        name  = "PGHOST"
        value = azurerm_postgresql_flexible_server.postgreSQL.fqdn
      }

      env {
        name  = "PGDATABASE"
        value = "postgres"
      }

      env {
        name  = "PGUSER"
        value = data.terraform_remote_state.bootstrap.outputs.bdd_group_members_name
      }
    }
  }
  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }
}

resource "azurerm_container_app_job" "database_migration" {
  name                         = "database-migration"
  location                     = data.azurerm_resource_group.TaskManagerResourceGroup.location
  resource_group_name          = data.azurerm_resource_group.TaskManagerResourceGroup.name
  container_app_environment_id = azurerm_container_app_environment.container_app_env.id
  workload_profile_name        = "Consumption"

  replica_timeout_in_seconds = 120
  replica_retry_limit        = 0

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      data.terraform_remote_state.bootstrap.outputs.backend_runtime_identity_id,
      data.terraform_remote_state.bootstrap.outputs.bdd_admin_id,
    ]
  }

  registry {
    server   = data.terraform_remote_state.bootstrap.outputs.acr_login_server
    identity = data.terraform_remote_state.bootstrap.outputs.backend_runtime_identity_id
  }

  template {
    container {
      name    = "database-migration"
      image   = "mcr.microsoft.com/k8se/quickstart:latest"
      command = ["npm", "run", "prisma:deploy:entra"]
      cpu     = 0.25
      memory  = "0.5Gi"

      env {
        name  = "AZURE_CLIENT_ID"
        value = data.terraform_remote_state.bootstrap.outputs.bdd_admin_client_id
      }

      env {
        name  = "PGHOST"
        value = azurerm_postgresql_flexible_server.postgreSQL.fqdn
      }

      env {
        name  = "PGDATABASE"
        value = "postgres"
      }

      env {
        name  = "PGUSER"
        value = data.terraform_remote_state.bootstrap.outputs.postgresql_admin_group_name
      }

      env {
        name  = "PG_APP_GROUP_NAME"
        value = data.terraform_remote_state.bootstrap.outputs.bdd_group_members_name
      }
      env {
        name  = "PG_APP_GROUP_OBJECT_ID"
        value = data.terraform_remote_state.bootstrap.outputs.bdd_group_members_id
      }
      env {
        name = "DATABASE_URL"
      }

    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
}