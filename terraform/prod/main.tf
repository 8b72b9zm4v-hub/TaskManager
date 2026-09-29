data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

data "azurerm_resource_group" "TaskManagerResourceGroup" {
  name = "TaskManager"
}

data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"

  config = {
    use_azuread_auth     = true
    storage_account_name = var.state_storage
    container_name       = "tfstate"
    key                  = "bootstrapt.terraform.tfstate"
  }
}




