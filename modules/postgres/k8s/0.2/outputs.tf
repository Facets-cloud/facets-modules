locals {
  writer_db_output = {
    "writer-0" = {
      host     = "postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local"
      username = "postgres"
      password = module.writer-password.result
      port     = "5432"
      name     = "writer-0"
      db_names = lookup(local.spec, "db_names", [])
    }
  }
  reader_db_output = {
    for index in range(local.replica_count) :
    "reader-${index}" => {
      host     = "postgres-${local.name}-postgresql-reader.${local.namespace}.svc.cluster.local"
      username = "repl_user"
      password = module.read-replica-password.result
      port     = "5432"
      name     = "reader-${index}"
      db_names = lookup(local.spec, "db_names", [])
    }
  }
  defaultDatabase   = "postgres"
  excludedDatabases = []

  output_interfaces = {
    reader = local.replica_count == 0 ? {
      host              = "postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local"
      username          = "postgres"
      password          = sensitive(module.writer-password.result)
      port              = "5432"
      connection_string = sensitive("postgres://postgres:${module.writer-password.result}@postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local:5432")
      secrets           = ["password", "connection_string"]
      db_names          = lookup(local.spec, "db_names", [])
      } : {
      host              = "postgres-${local.name}-postgresql-reader.${local.namespace}.svc.cluster.local"
      username          = "repl_user"
      password          = sensitive(module.read-replica-password.result)
      port              = "5432"
      connection_string = sensitive("postgres://repl_user:${module.read-replica-password.result}@postgres-${local.name}-postgresql-reader.${local.namespace}.svc.cluster.local:5432")
      secrets           = ["password", "connection_string"]
      db_names          = lookup(local.spec, "db_names", [])
    }
    writer = {
      host              = "postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local"
      username          = "postgres"
      password          = sensitive(module.writer-password.result)
      port              = "5432"
      connection_string = sensitive("postgres://postgres:${module.writer-password.result}@postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local:5432")
      secrets           = ["password", "connection_string"]
      db_names          = lookup(local.spec, "db_names", [])
    }
  }

  output_attributes = {
    pod_prefix = {
      writer = "postgres-${local.name}-postgresql-writer"
      reader = "postgres-${local.name}-postgresql-reader"
    }
    selectors = {
      postgres = {
        "app.kubernetes.io/instance" = "postgres-${local.name}"
        "app.kubernetes.io/name"     = "postgresql"
      }
    }
    resource_type     = "postgres"
    resource_name     = var.instance_name
    instances         = local.writer_db_output
    defaultDatabase   = "postgres"
    postgresVersion   = local.spec.postgres_version
    excludedDatabases = []
  }
}

output "instances" {
  value = local.writer_db_output
}

output "postgresVersion" {
  value = local.spec.postgres_version
}
output "defaultDatabase" {
  value = local.defaultDatabase
}
output "excludedDatabases" {
  value = local.excludedDatabases
}

# For old module compatibility

output "writer_host" {
  value = "postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local"
}
output "writer_port" {
  value = "5432"
}
output "writer_username" {
  value = "postgres"
}
output "writer_password" {
  value = module.writer-password.result
}
output "writer_connection_string" {
  value = "jdbc:postgresql://postgres:${module.writer-password.result}@postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local:5432/"
}
output "reader_host" {
  value = "postgres-${local.name}-postgresql-reader.${local.namespace}.svc.cluster.local"
}
output "reader_port" {
  value = "5432"
}
output "reader_username" {
  value = "repl_user"
}
output "reader_password" {
  value = module.read-replica-password.result
}
