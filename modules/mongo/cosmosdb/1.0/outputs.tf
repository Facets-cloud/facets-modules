locals {
  output_attributes = {
    id                     = azurerm_cosmosdb_account.main.id
    endpoint               = azurerm_cosmosdb_account.main.endpoint
    location               = azurerm_cosmosdb_account.main.location
    name                   = azurerm_cosmosdb_account.main.name
    resource_group_name    = azurerm_cosmosdb_account.main.resource_group_name
    kind                   = azurerm_cosmosdb_account.main.kind
    consistency_policy     = azurerm_cosmosdb_account.main.consistency_policy
    geo_locations          = azurerm_cosmosdb_account.main.geo_location
    capabilities           = azurerm_cosmosdb_account.main.capabilities
    backup_policy          = azurerm_cosmosdb_account.main.backup
    primary_key            = azurerm_cosmosdb_account.main.primary_key
    secondary_key          = azurerm_cosmosdb_account.main.secondary_key
    primary_readonly_key   = azurerm_cosmosdb_account.main.primary_readonly_key
    secondary_readonly_key = azurerm_cosmosdb_account.main.secondary_readonly_key
    read_endpoints         = azurerm_cosmosdb_account.main.read_endpoints
    write_endpoints        = azurerm_cosmosdb_account.main.write_endpoints
    connection_strings     = [azurerm_cosmosdb_account.main.primary_mongodb_connection_string]
    databases              = { for db_name, db in azurerm_cosmosdb_mongo_database.databases : db_name => { name = db.name, id = db.id, throughput = try(db.throughput, null), autoscale_settings = try(db.autoscale_settings, null) } }
    collections            = { for collection_key, collection in azurerm_cosmosdb_mongo_collection.collections : collection_key => { name = collection.name, database_name = collection.database_name, shard_key = collection.shard_key, default_ttl_seconds = collection.default_ttl_seconds, id = collection.id } }
    private_endpoint       = var.instance.spec.networking.private_endpoint.enabled ? { id = azurerm_private_endpoint.cosmosdb[0].id, private_service_connection = azurerm_private_endpoint.cosmosdb[0].private_service_connection, network_interface = azurerm_private_endpoint.cosmosdb[0].network_interface } : null
    diagnostic_setting     = var.instance.spec.monitoring.diagnostic_setting.enabled ? { id = azurerm_monitor_diagnostic_setting.cosmosdb[0].id, name = azurerm_monitor_diagnostic_setting.cosmosdb[0].name } : null
  }
  output_interfaces = {
    endpoint           = azurerm_cosmosdb_account.main.endpoint
    primary_key        = azurerm_cosmosdb_account.main.primary_key
    secondary_key      = azurerm_cosmosdb_account.main.secondary_key
    connection_strings = azurerm_cosmosdb_account.main.primary_mongodb_connection_string
  }
}