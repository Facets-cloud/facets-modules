# Diagnostic settings for CosmosDB
resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  count = var.instance.spec.monitoring.diagnostic_setting.enabled ? 1 : 0

  name               = "${local.cosmosdb_account_name}-diagnostics"
  target_resource_id = azurerm_cosmosdb_account.main.id

  # Log Analytics Workspace
  log_analytics_workspace_id = var.instance.spec.monitoring.diagnostic_setting.log_analytics_workspace_id != "" ? var.instance.spec.monitoring.diagnostic_setting.log_analytics_workspace_id : null

  # Storage Account
  storage_account_id = var.instance.spec.monitoring.diagnostic_setting.storage_account_id != "" ? var.instance.spec.monitoring.diagnostic_setting.storage_account_id : null

  # Event Hub
  eventhub_authorization_rule_id = var.instance.spec.monitoring.diagnostic_setting.eventhub_authorization_rule_id != "" ? var.instance.spec.monitoring.diagnostic_setting.eventhub_authorization_rule_id : null

  # Log categories
  dynamic "enabled_log" {
    for_each = var.instance.spec.monitoring.diagnostic_setting.log_categories.data_plane_requests ? ["DataPlaneRequests"] : []
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = var.instance.spec.monitoring.diagnostic_setting.log_categories.mongo_requests ? ["MongoRequests"] : []
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = var.instance.spec.monitoring.diagnostic_setting.log_categories.query_runtime_statistics ? ["QueryRuntimeStatistics"] : []
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = var.instance.spec.monitoring.diagnostic_setting.log_categories.control_plane_requests ? ["ControlPlaneRequests"] : []
    content {
      category = enabled_log.value
    }
  }

  # Metrics
  dynamic "metric" {
    for_each = var.instance.spec.monitoring.diagnostic_setting.enable_metrics ? ["AllMetrics"] : []
    content {
      category = metric.value
      enabled  = true
    }
  }

  depends_on = [azurerm_cosmosdb_account.main]
}