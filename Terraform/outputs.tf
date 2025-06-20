output "function_app_url" {
  value = azurerm_linux_function_app.function_app.default_hostname
}

output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}

output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.app_insights.instrumentation_key
  sensitive = true
}

output "application_insights_connection_string" {
  value     = azurerm_application_insights.app_insights.connection_string
  sensitive = true
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}