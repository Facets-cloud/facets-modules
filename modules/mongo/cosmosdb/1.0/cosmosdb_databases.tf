# Create MongoDB databases
resource "azurerm_cosmosdb_mongo_database" "databases" {
  for_each = var.instance.spec.databases.database_configs

  name                = each.key
  resource_group_name = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group.name
  account_name        = azurerm_cosmosdb_account.main.name

  # Database-level throughput configuration
  throughput = var.instance.spec.databases.database_throughput.type == "standard" ? var.instance.spec.databases.database_throughput.standard_ru : null

  dynamic "autoscale_settings" {
    for_each = var.instance.spec.databases.database_throughput.type == "autoscale" ? [1] : []
    content {
      max_throughput = var.instance.spec.databases.database_throughput.max_autoscale_ru
    }
  }

  depends_on = [azurerm_cosmosdb_account.main]
}

# Flatten collections for iteration
locals {
  collections = flatten([
    for db_name, db_config in var.instance.spec.databases.database_configs : [
      for collection_name, collection_config in db_config.collections : {
        db_name             = db_name
        collection_name     = collection_name
        shard_key           = collection_config.shard_key
        default_ttl_seconds = collection_config.default_ttl_seconds
        indexes             = collection_config.indexes
        key                 = "${db_name}-${collection_name}"
      }
    ]
  ])

  collections_map = {
    for collection in local.collections : collection.key => collection
  }
}

# Create MongoDB collections
resource "azurerm_cosmosdb_mongo_collection" "collections" {
  for_each = local.collections_map

  name                = each.value.collection_name
  resource_group_name = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_mongo_database.databases[each.value.db_name].name

  # Shard key configuration
  shard_key = each.value.shard_key

  # TTL configuration
  default_ttl_seconds = each.value.default_ttl_seconds

  # Custom indexes
  dynamic "index" {
    for_each = each.value.indexes
    content {
      keys   = index.value.keys
      unique = try(index.value.unique, false)
    }
  }

  depends_on = [azurerm_cosmosdb_mongo_database.databases]

  lifecycle {
    ignore_changes = [
      # Ignore changes to indexes that might be managed externally
      index,
    ]
  }
}