# Generate unique name for CosmosDB account using Facets utility module
module "unique_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 44
  resource_name   = var.instance_name
  resource_type   = "mongo"
  is_k8s          = false
  globally_unique = true
}

locals {
  cosmosdb_account_name = module.unique_name.name

  # Parse IP ranges if provided
  ip_range_filter = var.instance.spec.networking.ip_range_filter.enabled && var.instance.spec.networking.ip_range_filter.allowed_ips != "" ? split(",", replace(var.instance.spec.networking.ip_range_filter.allowed_ips, " ", "")) : []

  # Parse subnet IDs if provided
  virtual_network_subnet_ids = var.instance.spec.networking.virtual_network_rules.enabled && lookup(var.instance.spec.networking.virtual_network_rules, "subnet_ids", "") != "" ? split(",", replace(var.instance.spec.networking.virtual_network_rules.subnet_ids, " ", "")) : []

  # Parse identity IDs if provided
  identity_ids = lookup(var.instance.spec.security.identity, "identity_ids", "") != "" ? split(",", replace(var.instance.spec.security.identity.identity_ids, " ", "")) : []

  # Build capabilities list based on configuration
  capabilities = concat(
    ["EnableMongo"],
    var.instance.spec.account_config.capabilities.enable_aggregation_pipeline ? ["EnableAggregationPipeline"] : [],
    var.instance.spec.account_config.capabilities.enable_doc_level_ttl ? ["mongoEnableDocLevelTTL"] : [],
    var.instance.spec.account_config.capabilities.disable_rate_limiting_responses ? ["DisableRateLimitingResponses"] : [],
    # Add MongoDB version capability based on server version
    ["MongoDBv3.4"]
  )

  # Determine geo locations
  geo_locations = concat(
    [{
      location          = var.instance.spec.geo_locations.primary_location
      failover_priority = 0
    }],
    var.instance.spec.geo_locations.secondary_locations.enabled ?
    [for region_name, region_config in var.instance.spec.geo_locations.secondary_locations.regions : {
      location          = region_config.location
      failover_priority = region_config.failover_priority
    }] : []
  )

  # Default tags to apply to all resources
  default_tags = merge(
    var.environment.cloud_tags,
    {
      resourceType = "mongo"
      resourceName = local.cosmosdb_account_name
    }
  )
}

# CosmosDB Account
resource "azurerm_cosmosdb_account" "main" {
  provider            = "azurerm4-8-0"
  name                = local.cosmosdb_account_name
  location            = var.cluster.region
  resource_group_name = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group
  offer_type          = "Standard"
  kind                = "MongoDB"

  automatic_failover_enabled        = var.instance.spec.account_config.enable_automatic_failover
  multiple_write_locations_enabled  = var.instance.spec.account_config.enable_multiple_write_locations
  is_virtual_network_filter_enabled = var.instance.spec.networking.virtual_network_rules.enabled
  analytical_storage_enabled        = var.instance.spec.account_config.analytical_storage_enabled
  public_network_access_enabled     = var.instance.spec.account_config.public_network_access_enabled
  mongo_server_version              = var.instance.spec.mongo_server_version

  # IP range filter for firewall
  ip_range_filter = local.ip_range_filter

  # Capabilities
  dynamic "capabilities" {
    for_each = local.capabilities
    content {
      name = capabilities.value
    }
  }

  # Consistency policy
  consistency_policy {
    consistency_level       = var.instance.spec.consistency_policy.consistency_level
    max_interval_in_seconds = var.instance.spec.consistency_policy.consistency_level == "BoundedStaleness" ? var.instance.spec.consistency_policy.max_interval_in_seconds : null
    max_staleness_prefix    = var.instance.spec.consistency_policy.consistency_level == "BoundedStaleness" ? var.instance.spec.consistency_policy.max_staleness_prefix : null
  }

  # Geographic locations
  dynamic "geo_location" {
    for_each = local.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
    }
  }

  # Virtual network rules
  dynamic "virtual_network_rule" {
    for_each = local.virtual_network_subnet_ids
    content {
      id = virtual_network_rule.value
    }
  }

  # Backup configuration
  backup {
    type                = var.instance.spec.backup.type
    interval_in_minutes = var.instance.spec.backup.type == "Periodic" && var.instance.spec.backup.periodic_config != null ? var.instance.spec.backup.periodic_config.interval_in_minutes : null
    retention_in_hours  = var.instance.spec.backup.type == "Periodic" && var.instance.spec.backup.periodic_config != null ? var.instance.spec.backup.periodic_config.retention_in_hours : null
    storage_redundancy  = var.instance.spec.backup.type == "Periodic" && var.instance.spec.backup.periodic_config != null ? var.instance.spec.backup.periodic_config.storage_redundancy : null
    tier                = var.instance.spec.backup.type == "Continuous" && lookup(var.instance.spec.backup, "continuous_config", null) != null ? lookup(var.instance.spec.backup.continuous_config, "tier", null) : null
  }

  # Identity configuration
  dynamic "identity" {
    for_each = var.instance.spec.security.identity.type != null ? [1] : []
    content {
      type         = var.instance.spec.security.identity.type
      identity_ids = contains(["UserAssigned", "SystemAssigned,UserAssigned"], var.instance.spec.security.identity.type) && length(local.identity_ids) > 0 ? local.identity_ids : null
    }
  }

  # Customer managed key
  key_vault_key_id = var.instance.spec.security.customer_managed_key.enabled ? var.instance.spec.security.customer_managed_key.key_vault_key_id : null

  tags = local.default_tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to backup configuration that might be managed externally
      backup[0].interval_in_minutes,
      backup[0].retention_in_hours,
    ]
  }
}
