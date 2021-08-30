
#terraform {
# backend "azurerm" {}
#}

###################
## Provider
####################

provider "azurerm" {
 version         = "=2.18.0"
 subscription_id = var.acr_subscription_id
 features {}
 skip_provider_registration = "true"
}

#provider "azuread" {
# version = "=0.7.0"
#}


###################
## Identity
####################

data "azurerm_user_assigned_identity" "assigned_identity_acr_pull" {
 provider            = azurerm.acr_sub
 name                = "User_ACR_pull"
 resource_group_name = "MYRG"
}
