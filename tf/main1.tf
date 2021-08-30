
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
 resource_group_name = "RG"
}


##################
# app service plan 
##################

resource "azurerm_app_service_plan" "my_service_plan" {
 name                = "my_service_plan"
 location            = "west us"
 resource_group_name = "RG"
 kind                = "Linux"
 reserved            = true

 sku {
   tier     = "Standard"
   size     = "S1"
   capacity = "3"
 }
}


##############
#  app service
##############

resource "azurerm_app_service" "my_app_service_container" {
 name                    = "my_app_service_container"
 location                = "west us"
 resource_group_name     = "RG"
 app_service_plan_id     = azurerm_app_service_plan.my_service_plan.id
 https_only              = true
 client_affinity_enabled = true
 site_config {
   scm_type  = "VSTSRM".  # or can be "LocalGit"
   always_on = "true"
   linux_fx_version  = "DOCKER|arc01.azurecr.io/myapp:latest" 
   health_check_path = "/health" # health check required in order that internal app service plan loadbalancer do not loadbalance on instance down
 }
 identity {
   type         = "SystemAssigned, UserAssigned"
   identity_ids = [data.azurerm_user_assigned_identity.assigned_identity_acr_pull.id]
 }
 app_settings = local.env_variables 
}
 connection_string {
   name  = "Database"
   type  = "SQLServer"
   value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
}


##################
## app service - staging slot
##################

resource "azurerm_app_service_slot" "my_app_service_container_staging" {
 name                    = "staging"
 app_service_name        = azurerm_app_service.my_app_service_container.name
 location                = "west us"
 resource_group_name     = "RG"
 app_service_plan_id     = azurerm_app_service_plan.my_service_plan.id
 https_only              = true
 client_affinity_enabled = true
 site_config {
   scm_type          = "VSTSRM". # or can be "LocalGit"
   always_on         = "true"
   health_check_path = "/login"
 }
 identity {
   type         = "SystemAssigned, UserAssigned"
   identity_ids = [data.azurerm_user_assigned_identity.assigned_identity_acr_pull.id]
 }
 app_settings = local.env_variables 
}
 connection_string {
   name  = "Database"
   type  = "SQLServer"
   value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
}



resource "azurerm_application_insights" "my_app_insight" {
 name                = "my_app_insight"
 location            = "France central"
 resource_group_name = "MYRG"
 application_type    = "Node.JS" # Depends on your application
 disable_ip_masking  = true
 retention_in_days   = 730
}
