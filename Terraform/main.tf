terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.33.0" // https://registry.terraform.io/providers/hashicorp/azurerm/latest
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "resource_group" {
  location = var.location
  name     = var.project_name
  tags     = var.tags
}

resource "azurerm_storage_account" "storage_account" {
  account_replication_type = "LRS" // Locally redundant storage
  account_tier        = "Standard"
  location            = azurerm_resource_group.resource_group.location
  name                = "azfuncexplore7x9k"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = var.tags
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  location            = azurerm_resource_group.resource_group.location
  name                = var.project_name
  resource_group_name = azurerm_resource_group.resource_group.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
  tags                = var.tags
}

resource "azurerm_application_insights" "app_insights" {
  application_type    = "web"
  location            = azurerm_resource_group.resource_group.location
  name                = var.project_name
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = var.tags
  workspace_id        = azurerm_log_analytics_workspace.log_analytics.id
}

resource "azurerm_service_plan" "service_plan" {
  location            = azurerm_resource_group.resource_group.location
  name                = var.project_name
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "Y1" // Consumption
  tags                = var.tags
}

resource "azurerm_linux_function_app" "function_app" {
  functions_extension_version = "~4"
  location                    = azurerm_resource_group.resource_group.location
  name                        = var.project_name
  resource_group_name         = azurerm_resource_group.resource_group.name
  service_plan_id             = azurerm_service_plan.service_plan.id
  storage_account_access_key  = azurerm_storage_account.storage_account.primary_access_key
  storage_account_name        = azurerm_storage_account.storage_account.name
  tags                        = var.tags

  site_config {
    application_stack {
      dotnet_version = "9.0"
    }
  }

  lifecycle {
    ignore_changes = [
      site_config[0].application_insights_connection_string
    ]
  }

  app_settings = {
    "AzureWebJobsStorage"                   = azurerm_storage_account.storage_account.primary_connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "dotnet-isolated"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
  }
}