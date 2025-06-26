locals {
  username = "default"
  reader = {
    for index in range(local.redis_replica_count) :
    "reader-${index}" => {
      host     = azurerm_redis_cache.facets_azure_redis.hostname
      password = local.spec.authenticated ? sensitive(azurerm_redis_cache.facets_azure_redis.secondary_access_key) : ""
      port     = local.spec.authenticated ? tostring(azurerm_redis_cache.facets_azure_redis.ssl_port) : tostring(azurerm_redis_cache.facets_azure_redis.port)
      instance = azurerm_redis_cache.facets_azure_redis.id
      name     = "reader-${index}"

    }
  }
  writer = {
    for index in range(local.redis_replica_count) :
    "writer-${index}" => {
      host     = azurerm_redis_cache.facets_azure_redis.hostname
      instance = azurerm_redis_cache.facets_azure_redis.id
      password = local.spec.authenticated ? sensitive(azurerm_redis_cache.facets_azure_redis.primary_access_key) : ""
      port     = local.spec.authenticated ? tostring(azurerm_redis_cache.facets_azure_redis.ssl_port) : tostring(azurerm_redis_cache.facets_azure_redis.port)
      name     = "writer-${index}"
    }
  }

  output_interfaces = {
    writer = {
      host              = azurerm_redis_cache.facets_azure_redis.hostname
      username          = local.spec.authenticated ? local.username : ""
      password          = local.spec.authenticated ? sensitive(azurerm_redis_cache.facets_azure_redis.primary_access_key) : ""
      port              = local.spec.authenticated ? tostring(azurerm_redis_cache.facets_azure_redis.ssl_port) : tostring(azurerm_redis_cache.facets_azure_redis.port)
      connection_string = local.spec.authenticated ? sensitive("redis://${local.username}:${azurerm_redis_cache.facets_azure_redis.primary_access_key}@${azurerm_redis_cache.facets_azure_redis.hostname}:${tostring(azurerm_redis_cache.facets_azure_redis.ssl_port)}/") : "redis://${azurerm_redis_cache.facets_azure_redis.hostname}:6379/"
      secrets           = local.spec.authenticated ? ["password", "connection_string"] : ["password"]

    }
    reader = local.redis_replica_count == 0 ? {
      host              = azurerm_redis_cache.facets_azure_redis.hostname
      username          = local.spec.authenticated ? local.username : ""
      password          = local.spec.authenticated ? sensitive(azurerm_redis_cache.facets_azure_redis.primary_access_key) : ""
      port              = local.spec.authenticated ? tostring(azurerm_redis_cache.facets_azure_redis.ssl_port) : tostring(azurerm_redis_cache.facets_azure_redis.port)
      connection_string = local.spec.authenticated ? sensitive("redis://${local.username}:${azurerm_redis_cache.facets_azure_redis.primary_access_key}@${azurerm_redis_cache.facets_azure_redis.hostname}:${tostring(azurerm_redis_cache.facets_azure_redis.ssl_port)}/") : "redis://${azurerm_redis_cache.facets_azure_redis.hostname}:6379/"
      secrets           = local.spec.authenticated ? ["password", "connection_string"] : ["password"]
      } : {
      host              = azurerm_redis_cache.facets_azure_redis.hostname
      username          = local.spec.authenticated ? local.username : ""
      password          = local.spec.authenticated ? sensitive(azurerm_redis_cache.facets_azure_redis.secondary_access_key) : ""
      port              = local.spec.authenticated ? tostring(azurerm_redis_cache.facets_azure_redis.ssl_port) : tostring(azurerm_redis_cache.facets_azure_redis.port)
      connection_string = local.spec.authenticated ? sensitive("redis://${local.username}:${azurerm_redis_cache.facets_azure_redis.secondary_access_key}@${azurerm_redis_cache.facets_azure_redis.hostname}:${tostring(azurerm_redis_cache.facets_azure_redis.ssl_port)}/") : "redis://${azurerm_redis_cache.facets_azure_redis.hostname}:6379/"
      secrets           = local.spec.authenticated ? ["password", "connection_string"] : ["password"]

    }
  }
  output_attributes = {
    resource_type = "redis"
    resource_name = var.instance_name
    authenticated = local.authenticated
    instances     = merge(local.writer, local.reader)
    secrets       = local.authenticated ? ["instances"] : []
  }
}



output "instances" {
  value = merge(local.writer, local.reader)
}

output "authenticated" {
  value = local.authenticated
}

output "spec" {
  value = {
    authenticated = azurerm_redis_cache.facets_azure_redis.redis_configuration[0].enable_authentication
    redis_version = azurerm_redis_cache.facets_azure_redis.redis_version
    size = {
      reader = {
        capacity = local.capacity
      }
      writer = {
        capacity = local.capacity
      }
    }
  }
}

# For old module compatibility

output "writer_host" {
  value = azurerm_redis_cache.facets_azure_redis.hostname
}
output "writer_port" {
  value = local.spec.authenticated ? tostring(azurerm_redis_cache.facets_azure_redis.ssl_port) : tostring(azurerm_redis_cache.facets_azure_redis.port)
}
output "writer_username" {
  value = ""
  # sensitive = true
}
output "writer_password" {
  value = azurerm_redis_cache.facets_azure_redis.primary_access_key
  # sensitive = true
}
output "writer_connection_string" {
  value = azurerm_redis_cache.facets_azure_redis.primary_connection_string
}
output "reader_host" {
  value = azurerm_redis_cache.facets_azure_redis.hostname
}
output "reader_port" {
  value = local.spec.authenticated ? tostring(azurerm_redis_cache.facets_azure_redis.ssl_port) : tostring(azurerm_redis_cache.facets_azure_redis.port)
}
output "reader_username" {
  value = ""
  # sensitive = true
}
output "reader_password" {
  value = azurerm_redis_cache.facets_azure_redis.secondary_access_key
  # sensitive = true
}
output "reader_connection_string" {
  value = azurerm_redis_cache.facets_azure_redis.secondary_connection_string
}
