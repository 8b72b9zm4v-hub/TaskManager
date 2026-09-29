# Managed identities
resource "azurerm_user_assigned_identity" "taskmanager_ci_deployer" {
  location            = azurerm_resource_group.TaskManagerResourceGroup.location
  name                = "taskmanager-ci-deployer"
  resource_group_name = azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_user_assigned_identity" "taskmanager-ci-planner" {
  location            = azurerm_resource_group.TaskManagerResourceGroup.location
  name                = "taskmanager-ci-planner"
  resource_group_name = azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_user_assigned_identity" "acr_pull_container_app" {
  location            = azurerm_resource_group.TaskManagerResourceGroup.location
  name                = "acr_pull_container_app"
  resource_group_name = azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_user_assigned_identity" "bdd_user" {
  location            = azurerm_resource_group.TaskManagerResourceGroup.location
  name                = "bdd_user"
  resource_group_name = azurerm_resource_group.TaskManagerResourceGroup.name
}


# Nouveau rôle RBAC :
resource "azurerm_role_definition" "planner_secret_reader" {
  name        = "Terraform Planner Secret Reader"
  scope       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  description = "Allows Terraform plan to refresh required application secrets."

  permissions {
    actions = [
      "Microsoft.App/containerApps/listSecrets/action",
      "Microsoft.Web/staticSites/listSecrets/action",
      "Microsoft.Web/staticSites/listAppSettings/action",
    ]
  }

  assignable_scopes = [
    azurerm_resource_group.TaskManagerResourceGroup.id
  ]
}
# Assignement
resource "azurerm_role_assignment" "planner_secret_reader" {
  scope              = azurerm_resource_group.TaskManagerResourceGroup.id
  role_definition_id = azurerm_role_definition.planner_secret_reader.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.taskmanager-ci-planner.principal_id
}

resource "azurerm_role_assignment" "app_container_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_pull_container_app.principal_id
}

resource "azurerm_role_assignment" "ci_deployer_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.taskmanager_ci_deployer.principal_id
}

resource "azurerm_role_assignment" "reader-planer" {
  scope                = azurerm_resource_group.TaskManagerResourceGroup.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.taskmanager-ci-planner.principal_id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor_ci_plan" {
  scope                = azurerm_storage_container.storage_container.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.taskmanager-ci-planner.principal_id
}
resource "azurerm_role_assignment" "ci_deployer_contributor" {
  scope                = azurerm_resource_group.TaskManagerResourceGroup.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.taskmanager_ci_deployer.principal_id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_container.storage_container.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.taskmanager_ci_deployer.principal_id
}
# Identité fédéré
resource "azurerm_federated_identity_credential" "taskmanager-ci-planner" {
  name                      = "taskmanager-ci-planner"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.taskmanager-ci-planner.id

  subject = var.taskmanager-ci-planner_subject
}


resource "azurerm_federated_identity_credential" "github_main" {
  name                      = "github-production"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.taskmanager_ci_deployer.id

  subject = var.github_main_subject
}


resource "azuread_group" "bdd_members" {
  display_name     = "PG TaskManager Members"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
  members = [
    data.azuread_client_config.current.object_id,
    azurerm_user_assigned_identity.bdd_user.principal_id
  ]
}

resource "azuread_group" "postgresql_admin_group_name" {
  display_name     = "PG admin group"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
  members = [
    data.azuread_client_config.current.object_id,
  ]
}