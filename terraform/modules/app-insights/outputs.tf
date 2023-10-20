output "connection_string" {
    value = azurerm_application_insights.app_insights.connection_string
}

output "log_analytics_workspace_id" {
    value = azurerm_log_analytics_workspace.app_workspace.id
}