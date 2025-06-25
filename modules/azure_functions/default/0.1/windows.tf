# TODO Windows
locals {
  windows_function                = lookup(local.advanced, "windows", {})
  windows_app_config              = lookup(local.windows_function, "windows_app_config", {})
  windows_app_site_config         = lookup(local.windows_app_config, "site_config", {})
  windows_deployment_slots        = lookup(local.windows_app_config, "windows_deployment_slots", {})
  windows_cors_config             = lookup(local.windows_app_site_config, "cors", null)
  windows_app_service_logs_config = lookup(local.windows_app_site_config, "app_service_logs", null)
}
resource "azurerm_windows_function_app" "windows_function_app" {
  provider   = "azurerm3"
  depends_on = [data.aws_s3_bucket.customer-bucket, null_resource.download_s3_zips]
  count      = local.os == "Windows" ? 1 : 0

  name                = "${local.name}-function-app"
  resource_group_name = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group
  location            = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.location

  #stoarage account and service plan details
  storage_account_name       = azurerm_storage_account.az_func_storage_account.name
  storage_account_access_key = azurerm_storage_account.az_func_storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.service_plan.id

  //spec
  app_settings              = local.app_setting
  virtual_network_subnet_id = local.subnet_id

  // Local path and file name of the packaged application
  zip_deploy_file = local.zip_file_key != null && local.zip_file_key != "" ? "${local.downloaded_file_dir}/${local.zip_file_key}" : null
  tags            = local.tags

  dynamic "site_config" {
    for_each = [local.windows_app_config]
    content {
      load_balancing_mode               = lookup(local.windows_app_site_config, "load_balancing_mode", null)
      always_on                         = lookup(local.windows_app_site_config, "always_on", null)
      api_definition_url                = lookup(local.windows_app_site_config, "api_definition_url", null)
      api_management_api_id             = lookup(local.windows_app_site_config, "api_management_api_id", null)
      app_command_line                  = lookup(local.windows_app_site_config, "app_command_line", null)
      app_scale_limit                   = lookup(local.windows_app_site_config, "app_scale_limit", null)
      default_documents                 = lookup(local.windows_app_site_config, "default_documents", null)
      ftps_state                        = lookup(local.windows_app_site_config, "ftps_state", "Disabled")
      health_check_path                 = lookup(local.windows_app_site_config, "health_check_path", null)
      health_check_eviction_time_in_min = lookup(local.windows_app_site_config, "health_check_eviction_time_in_min", null)
      http2_enabled                     = lookup(local.windows_app_site_config, "http2_enabled", null)
      managed_pipeline_mode             = lookup(local.windows_app_site_config, "managed_pipeline_mode", null)
      minimum_tls_version               = lookup(local.windows_app_site_config, "minimum_tls_version", lookup(local.windows_app_site_config, "min_tls_version", "1.2"))
      remote_debugging_enabled          = lookup(local.windows_app_site_config, "remote_debugging_enabled", false)
      remote_debugging_version          = lookup(local.windows_app_site_config, "remote_debugging_version", null)
      runtime_scale_monitoring_enabled  = lookup(local.windows_app_site_config, "runtime_scale_monitoring_enabled", null)
      use_32_bit_worker                 = lookup(local.windows_app_site_config, "use_32_bit_worker", null)
      websockets_enabled                = lookup(local.windows_app_site_config, "websockets_enabled", false)

      application_insights_connection_string = lookup(local.windows_app_site_config, "application_insights_connection_string", null)
      application_insights_key               = lookup(local.windows_app_site_config, "application_insights_key", false)

      pre_warmed_instance_count = lookup(local.windows_app_site_config, "pre_warmed_instance_count", null)
      elastic_instance_minimum  = lookup(local.windows_app_site_config, "elastic_instance_minimum", null)
      worker_count              = lookup(local.windows_app_site_config, "worker_count", null)

      vnet_route_all_enabled = lookup(local.windows_app_site_config, "vnet_route_all_enabled", null)

      # Spec > runtime
      dynamic "application_stack" {
        for_each = local.runtime.stack != null ? [local.runtime.stack] : []
        content {

          dotnet_version              = contains(["dotnet"], local.runtime.stack) ? local.runtime.version : null
          use_dotnet_isolated_runtime = contains(["dotnet_isolated"], local.runtime.stack) ? local.runtime.version : null

          java_version            = contains(["java"], local.runtime.stack) ? local.runtime.version : null
          node_version            = contains(["node"], local.runtime.stack) ? local.runtime.version : null
          powershell_core_version = contains(["powershell_core"], local.runtime.stack) ? local.runtime.version : null

          #TODO : use_custom_runtime - (Optional) Should the Linux Function App use a custom runtime?
          use_custom_runtime = contains(["custom_runtime"], local.runtime.stack) ? local.runtime.version : null
        }
      }
      dynamic "cors" {
        for_each = local.windows_cors_config != null ? [local.windows_cors_config] : []
        content {
          allowed_origins     = cors.value.allowed_origins
          support_credentials = cors.value.support_credentials
        }
      }
      dynamic "app_service_logs" {
        for_each = local.windows_app_service_logs_config != null ? [local.windows_app_service_logs_config] : []
        content {
          disk_quota_mb         = app_service_logs.value.disk_quota_mb
          retention_period_days = app_service_logs.value.retention_period_days
        }
      }
    }
  }
}

resource "azurerm_windows_function_app_slot" "windows_function_app_slot" {
  provider   = "azurerm3"
  depends_on = [azurerm_windows_function_app.windows_function_app[0]]
  for_each   = local.os == "Windows" && length(local.windows_deployment_slots) > 0 ? local.windows_deployment_slots : {}

  name                 = "${local.name}-slot-${each.key}"
  function_app_id      = azurerm_windows_function_app.windows_function_app[0].id
  storage_account_name = azurerm_storage_account.az_func_storage_account.name
  tags                 = local.tags
  app_settings = {
  }
  site_config {
    always_on = false
  }
}