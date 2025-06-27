module "az-function-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_name   = var.instance_name
  resource_type   = "functions"
  limit           = 53
  environment     = var.environment
}

module "az-function-sc-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = var.instance_name
  resource_type   = "azure-functions"
  limit           = 24
  environment     = var.environment
}

module "customer-env-bucket-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = "customer-functions-s3"
  resource_type   = "functions-s3-bucket"
  limit           = 40
  environment     = var.environment
}
locals {
  advanced            = lookup(lookup(var.instance, "advanced", {}), "azure_functions", {})
  spec                = var.instance.spec
  zip_path            = lookup(lookup(var.instance.spec, "release", {}), "zip_path", null)
  zip_file_key        = basename(local.zip_path)
  zip_file_s3_path    = dirname(local.zip_path)
  downloaded_file_dir = "${path.module}/${local.name}/${local.zip_file_s3_path}"
  #  is_public                = lookup(local.spec, "is_public", false) == true ? "Enabled" : "Disabled"
  subnet_id                     = lookup(local.spec, "in_vnet", true) ? var.inputs.network_details.attributes.legacy_outputs.vpc_details.functions_subnets[0] : null
  deploy_method                 = lookup(local.spec, "deploy_as", "code")
  app_setting                   = lookup(local.spec, "app_setting", {})
  size                          = lookup(local.spec, "size", {})
  runtime                       = lookup(local.spec, "runtime", null)
  name                          = module.az-function-name.name
  metadata                      = lookup(var.instance, "metadata", {})
  user_defined_tags             = lookup(local.metadata, "tags", {})
  tags                          = merge(local.user_defined_tags, var.environment.cloud_tags)
  os                            = lookup(var.instance.spec, "os", "Linux")
  sku                           = lookup(local.size, "sku", "Y1")
  storage_account               = lookup(local.advanced, "storage_account", {})
  service_plan                  = lookup(local.advanced, "service_plan", {})
  linux_function                = lookup(local.advanced, "linux", {})
  linux_app_config              = lookup(local.linux_function, "linux_app_config", {})
  linux_app_site_config         = lookup(local.linux_app_config, "site_config", {})
  linux_deployment_slots        = lookup(local.linux_function, "linux_deployment_slots", {})
  linux_cors_config             = lookup(local.linux_app_site_config, "cors", null)
  linux_app_service_logs_config = lookup(local.linux_app_site_config, "app_service_logs", null)
  adjusted_generated_name       = length(module.az-function-sc-name.name) > 24 ? substr(replace(module.az-function-sc-name.name, "-", ""), 0, 24) : replace(module.az-function-sc-name.name, "-", "")
}
data "aws_s3_bucket" "customer-bucket" {
  bucket   = lookup(local.advanced, "s3-bucket-name", var.cc_metadata.customer_artifact_bucket) // testing bucket in root account : "capillary-cloud-facetsdemo-zip-test"
  provider = aws.tooling
}
data "aws_s3_bucket_object" "customer-bucket-object" {
  depends_on = [data.aws_s3_bucket.customer-bucket]
  count      = local.zip_file_key != null && local.zip_file_key != "" ? 1 : 0
  bucket     = data.aws_s3_bucket.customer-bucket.id
  key        = local.zip_path
  provider   = aws.tooling
}

resource "null_resource" "download_s3_zips" {
  count    = local.zip_file_key != null && local.zip_file_key != "" ? 1 : 0
  triggers = {
    functions_zip = data.aws_s3_bucket_object.customer-bucket-object.0.version_id
  }
  depends_on = [data.aws_s3_bucket_object.customer-bucket-object, data.aws_s3_bucket.customer-bucket]
  provisioner "local-exec" {
    command = <<-EOT
      [ -d "${local.downloaded_file_dir}" ] || mkdir -p "${local.downloaded_file_dir}" &&
      aws s3api get-object --region ${var.cc_metadata.cc_region} --bucket ${data.aws_s3_bucket.customer-bucket.id} --key ${local.zip_path} "${local.downloaded_file_dir}/${local.zip_file_key}"
    EOT
  }
}


resource "azurerm_storage_account" "az_func_storage_account" {
  provider                 = "azurerm3"
  name                     = local.adjusted_generated_name
  resource_group_name      = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group
  location                 = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.location
  account_tier             = lookup(local.storage_account, "account_tier", "Standard")
  account_replication_type = lookup(local.storage_account, "account_replication_type", "LRS")
  tags                     = local.tags
}

resource "azurerm_service_plan" "service_plan" {
  provider = "azurerm3"
  name     = local.name
  #spec
  sku_name = lookup(local.spec, "sku", "Y1")
  os_type  = local.spec.os

  resource_group_name          = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group
  location                     = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.location
  worker_count                 = lookup(local.service_plan, "worker_count", null)
  zone_balancing_enabled       = lookup(local.service_plan, "zone_balancing_enabled", false)
  per_site_scaling_enabled     = lookup(local.service_plan, "per_site_scaling", false)
  maximum_elastic_worker_count = lookup(local.service_plan, "maximum_elastic_worker_count", null)
  tags                         = local.tags
}

resource "azurerm_linux_function_app" "linux_function_app" {
  provider   = "azurerm3"
  depends_on = [data.aws_s3_bucket.customer-bucket, null_resource.download_s3_zips]
  #  depends_on = [azurerm_service_plan.service_plan]
  count = local.os == "Linux" ? 1 : 0

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
  zip_deploy_file             = local.zip_file_key != null && local.zip_file_key != "" ? "${local.downloaded_file_dir}/${local.zip_file_key}" : null
  tags                        = local.tags
  functions_extension_version = lookup(local.linux_app_config, "functions_extension_version", null)
  #TODO:  add backup block, did not add was not in aster requirement
  #  dynamic "backup" {
  #    for_each = lookup(local.linux_app_config, "backup", null) == null ? [] : ["backup"]
  #    content {
  #      name                = lookup(local.linux_app_config.backup, "name", null)
  #      storage_account_url = lookup(local.linux_app_config.backup, "storage_account_url", null)
  #      dynamic "schedule" {
  #        for_each = lookup(local.linux_app_config.backup, "schedule", null) == null ? [] : ["schedule"]
  #        content {
  #          frequency_interval = lookup(local.linux_app_config.backup.schedule, "frequency_interval", null)
  #          frequency_unit     = lookup(local.linux_app_config.backup.schedule, "frequency_unit", null)
  #        }
  #      }
  #    }
  #  }
  dynamic "connection_string" {
    for_each = lookup(local.linux_app_config, "connection_string", null) == null ? [] : ["connection_string"]
    content {
      name  = lookup(lookup(local.linux_app_config, "connection_string", null), "name", null)
      type  = lookup(lookup(local.linux_app_config, "connection_string", null), "type", null)
      value = lookup(lookup(local.linux_app_config, "connection_string", null), "value", null)
    }
  }


  dynamic "site_config" {
    for_each = [local.linux_app_config]
    content {
      load_balancing_mode               = lookup(local.linux_app_site_config, "load_balancing_mode", null)
      always_on                         = lookup(local.linux_app_site_config, "always_on", null)
      api_definition_url                = lookup(local.linux_app_site_config, "api_definition_url", null)
      api_management_api_id             = lookup(local.linux_app_site_config, "api_management_api_id", null)
      app_command_line                  = lookup(local.linux_app_site_config, "app_command_line", null)
      app_scale_limit                   = lookup(local.linux_app_site_config, "app_scale_limit", null)
      default_documents                 = lookup(local.linux_app_site_config, "default_documents", null)
      ftps_state                        = lookup(local.linux_app_site_config, "ftps_state", "Disabled")
      health_check_path                 = lookup(local.linux_app_site_config, "health_check_path", null)
      health_check_eviction_time_in_min = lookup(local.linux_app_site_config, "health_check_eviction_time_in_min", null)
      http2_enabled                     = lookup(local.linux_app_site_config, "http2_enabled", null)
      managed_pipeline_mode             = lookup(local.linux_app_site_config, "managed_pipeline_mode", null)
      minimum_tls_version               = lookup(local.linux_app_site_config, "minimum_tls_version", lookup(local.linux_app_site_config, "min_tls_version", "1.2"))
      remote_debugging_enabled          = lookup(local.linux_app_site_config, "remote_debugging_enabled", false)
      remote_debugging_version          = lookup(local.linux_app_site_config, "remote_debugging_version", null)
      runtime_scale_monitoring_enabled  = lookup(local.linux_app_site_config, "runtime_scale_monitoring_enabled", null)
      use_32_bit_worker                 = lookup(local.linux_app_site_config, "use_32_bit_worker", null)
      websockets_enabled                = lookup(local.linux_app_site_config, "websockets_enabled", false)

      application_insights_connection_string = lookup(local.linux_app_site_config, "application_insights_connection_string", null)
      application_insights_key               = lookup(local.linux_app_site_config, "application_insights_key", false)

      pre_warmed_instance_count = lookup(local.linux_app_site_config, "pre_warmed_instance_count", null)
      elastic_instance_minimum  = lookup(local.linux_app_site_config, "elastic_instance_minimum", null)
      worker_count              = lookup(local.linux_app_site_config, "worker_count", null)

      vnet_route_all_enabled = lookup(local.linux_app_site_config, "vnet_route_all_enabled", null)

      # Spec > runtime
      dynamic "application_stack" {
        for_each = lookup(local.spec, "runtime", null) == null ? [] : ["application_stack"]
        content {
          dynamic "docker" {
            for_each = local.spec.runtime.stack == "docker" && local.deploy_method == "container" ? ["docker"] : []
            content {
              registry_url      = local.spec.runtime.stack == "docker" ? local.spec.runtime.registry_url : null
              image_name        = local.spec.runtime.stack == "docker" ? local.spec.runtimer.image_name : null
              image_tag         = local.spec.runtime.stack == "docker" ? local.spec.runtime.image_tag : null
              registry_username = local.spec.runtime.stack == "docker" ? lookup(local.spec.runtime, "registry_username", null) : null
              registry_password = local.spec.runtime.stack == "docker" ? lookup(local.spec.runtime, "registry_password", null) : null
            }
          }

          dotnet_version              = local.spec.runtime.stack == "dotnet" ? lookup(local.spec.runtime, "version", null) : null
          use_dotnet_isolated_runtime = local.spec.runtime.stack == "dotnet" ? lookup(local.spec.runtime, "use_dotnet_isolated_runtime", null) : null

          java_version            = local.spec.runtime.stack == "java" ? lookup(local.spec.runtime, "version", null) : null
          node_version            = local.spec.runtime.stack == "node" ? lookup(local.spec.runtime, "version", null) : null
          python_version          = local.spec.runtime.stack == "python" ? lookup(local.spec.runtime, "version", null) : null
          powershell_core_version = local.spec.runtime.stack == "powershell_core" ? lookup(local.spec.runtime, "version", null) : null

          #TODO : use_custom_runtime - (Optional) Should the Linux Function App use a custom runtime?
          use_custom_runtime = local.spec.runtime.stack == "custom_runtime" ? lookup(local.spec.runtime, "version", null) : null
        }
      }


      dynamic "cors" {
        for_each = local.linux_cors_config != null ? ["cors"] : []
        content {
          allowed_origins     = cors.value.allowed_origins
          support_credentials = cors.value.support_credentials
        }
      }
      dynamic "app_service_logs" {
        for_each = local.linux_app_service_logs_config != null ? ["app_service_logs"] : []
        content {
          disk_quota_mb         = app_service_logs.value.disk_quota_mb
          retention_period_days = app_service_logs.value.retention_period_days
        }
      }
    }
  }
}

// Added as version 3.52 does not have the support to updated  publicNetworkAccess = false.
// This resource is needed to enable/disable "is_public" when terraform version above 1.x
#resource "azapi_update_resource" "public-access" {
#  type      = "Microsoft.Web/sites@2022-03-01"
#  name      = azurerm_linux_function_app.linux_function_app[0].name
#  parent_id = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group_id
#  body = jsonencode({
#    properties = {
#      publicNetworkAccess = local.is_public
#    }
#  })
#  lifecycle {
#    replace_triggered_by = [
#      azurerm_linux_function_app.linux_function_app[0]
#    ]
#  }
#  depends_on = [
#    azurerm_linux_function_app.linux_function_app[0]
#  ]
#}

resource "azurerm_linux_function_app_slot" "linux_function_app_slot" {
  provider   = "azurerm3"
  depends_on = [azurerm_linux_function_app.linux_function_app[0]]
  for_each   = local.os == "Linux" && length(local.linux_deployment_slots) > 0 ? local.linux_deployment_slots : {}

  name                 = "${local.name}-slot-${each.key}"
  function_app_id      = azurerm_linux_function_app.linux_function_app[0].id
  storage_account_name = azurerm_storage_account.az_func_storage_account.name
  tags                 = local.tags
  app_settings = {
  }
  site_config {
    always_on = false
  }
}