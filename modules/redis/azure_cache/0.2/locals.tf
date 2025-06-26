locals {
  authenticated       = lookup(local.spec, "authenticated", true)
  advanced            = lookup(lookup(var.instance, "advanced", {}), "azure_cache", {})
  metadata            = lookup(var.instance, "metadata", {})
  user_defined_tags   = lookup(local.metadata, "tags", {})
  tags                = merge(local.user_defined_tags, var.environment.cloud_tags)
  resource_group_name = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group
  location            = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.location
  spec                = lookup(var.instance, "spec", {})
  size                = lookup(local.spec, "size", {})
  capacity            = lookup(local.size, "instance", "1")
  shards              = lookup(local.advanced, "shard_count", null)
  redis_replica_count = (lookup(local.size, "replica_count", lookup(local.size, "instance_count", 1)) > 3) ? 3 : lookup(local.size, "replica_count", lookup(local.size, "instance_count", 1))
  redis_config        = lookup(local.advanced, "redis_configuration", {})
  patch_schedule      = lookup(local.advanced, "patch_schedule", {})
  identity            = lookup(local.advanced, "identity", false)
  persistence         = lookup(local.spec, "persistence_enabled", false)
  rdb_storage         = lookup(local.redis_config, "rdb_storage_connection_string", null)
}