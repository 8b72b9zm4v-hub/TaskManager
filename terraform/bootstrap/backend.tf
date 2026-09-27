terraform {
  backend "azurerm" {
    use_azuread_auth     = true                                    # Can also be set via `ARM_USE_AZUREAD` environment variable.
    tenant_id            = "45f64ee1-87bf-4e25-b72e-b4f6f2fe0684"  # Can also be set via `ARM_TENANT_ID` environment variable.
    storage_account_name = "taskmanagerf0410d5947e4"                              # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    container_name       = "tfstate"                               # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "bootstrapt.terraform.tfstate"                # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
  }
}
