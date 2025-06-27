module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_name   = var.instance_name
  resource_type   = "redis"
  limit           = 53
  environment     = var.environment
}



resource "azurerm_redis_cache" "facets_azure_redis" {
  #required
  provider            = "azurerm3-105-0"
  name                = module.name.name
  location            = local.location
  resource_group_name = local.resource_group_name
  capacity            = local.capacity
  family              = "P"
  sku_name            = "Premium"
  redis_version       = lookup(local.spec, "redis_version", 6)

  #optionals
  replicas_per_primary          = local.redis_replica_count
  shard_count                   = local.shards
  replicas_per_master           = (local.shards == null) ? local.redis_replica_count : null #with premium sku not conjuction shards
  enable_non_ssl_port           = !local.authenticated
  minimum_tls_version           = lookup(local.advanced, "minimum_tls_version", "1.2")
  subnet_id                     = var.inputs.network_details.attributes.legacy_outputs.vpc_details.cache_subnets[0]
  private_static_ip_address     = lookup(local.advanced, "private_static_ip_address", null)
  public_network_access_enabled = lookup(local.advanced, "public_network_access_enabled", false)
  tags                          = local.tags


  redis_configuration {
    //optional
    enable_authentication           = local.authenticated
    maxmemory_reserved              = lookup(local.redis_config, "maxmemory_reserved", null)
    maxmemory_delta                 = lookup(local.redis_config, "maxmemory_delta", null)
    maxmemory_policy                = lookup(local.redis_config, "maxmemory_policy", "volatile-lru")
    maxfragmentationmemory_reserved = lookup(local.redis_config, "maxfragmentationmemory_reserved", null)
    rdb_backup_enabled              = (local.persistence == true && local.rdb_storage != null) ? true : null
    rdb_backup_frequency            = lookup(local.redis_config, "rdb_backup_frequency", null)
    rdb_backup_max_snapshot_count   = lookup(local.redis_config, "rdb_backup_max_snapshot_count", null)
    rdb_storage_connection_string   = local.rdb_storage
    aof_backup_enabled              = lookup(local.redis_config, "aof_backup_enabled", null)
    aof_storage_connection_string_0 = lookup(local.redis_config, "aof_storage_connection_string_0", null)
    aof_storage_connection_string_1 = lookup(local.redis_config, "aof_storage_connection_string_1", null)
    notify_keyspace_events          = lookup(local.redis_config, "notify_keyspace_events", null)
  }

  dynamic "identity" {
    for_each = local.identity ? [1] : [0]
    content {
      type = "SystemAssigned"
    }
  }

  patch_schedule {
    //required
    day_of_week = lookup(local.patch_schedule, "day_of_week", "Sunday")
    //optional
    start_hour_utc     = lookup(local.patch_schedule, "start_hour_utc", null)
    maintenance_window = lookup(local.patch_schedule, "maintenance_window", null)
  }
  # tenant_settings = {}
  # zones = []
}
