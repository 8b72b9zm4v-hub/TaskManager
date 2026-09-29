resource "azurerm_resource_group" "TaskManagerResourceGroup" {
  name     = "TaskManager"
  location = "France Central"
}

# IDENTITE DE DEPLOIEMENT
resource "azurerm_user_assigned_identity" "taskmanager_ci_deployer" {
  location            = azurerm_resource_group.TaskManagerResourceGroup.location
  name                = "taskmanager-ci-deployer"
  resource_group_name = azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_federated_identity_credential" "github_main" {
  name                      = "github-production"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.taskmanager_ci_deployer.id

  subject = "repo:8b72b9zm4v-hub@252215710/TaskManager@1367302588:ref:refs/heads/main"

}


#  BDD
resource "random_id" "storage_suffix" {
  byte_length = 6
}
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


# On applique les rôles sur le groupe de ressource
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

resource "azurerm_role_assignment" "ci_deployer_acr_push" {
  scope                = azurerm_resource_group.TaskManagerResourceGroup.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.taskmanager_ci_deployer.principal_id
}

# IDENTITE DE PLAN
resource "azurerm_user_assigned_identity" "taskmanager-ci-planner" {
  location            = azurerm_resource_group.TaskManagerResourceGroup.location
  name                = "taskmanager-ci-planner"
  resource_group_name = azurerm_resource_group.TaskManagerResourceGroup.name
}

resource "azurerm_federated_identity_credential" "taskmanager-ci-planner" {
  name                      = "taskmanager-ci-planner"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.taskmanager-ci-planner.id

  subject = "repo:8b72b9zm4v-hub@252215710/TaskManager@1367302588:pull_request"

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

data "azurerm_client_config" "current" {}
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

resource "azurerm_role_assignment" "planner_secret_reader" {
  scope              = azurerm_resource_group.TaskManagerResourceGroup.id
  role_definition_id = azurerm_role_definition.planner_secret_reader.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.taskmanager-ci-planner.principal_id
}
