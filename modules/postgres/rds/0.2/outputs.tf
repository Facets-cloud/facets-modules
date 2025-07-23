# Define your outputs here

locals {
  writer_hostname = split(":", module.rds_postgres_master.db_instance_endpoint)[0]
  writer_dbs = {
    "writer-0" = {
      name     = module.rds_postgres_master.db_instance_identifier
      host     = local.writer_hostname
      username = local.snapshot_identifier == null ? module.rds_postgres_master.db_instance_username : var.instance.spec.snapshot_username
      password = local.snapshot_identifier == null ? module.postgres_password.result : var.instance.spec.snapshot_password
      port     = module.rds_postgres_master.db_instance_port
    }
  }


  reader_dbs = local.reader_count > 0 ? {
    for index in range(local.reader_count) :
    "reader-${index}" => {
      name     = module.rds_postgres_replica["replica-${index}"].db_instance_identifier
      host     = split(":", module.rds_postgres_replica["replica-${index}"].db_instance_endpoint)[0]
      username = local.snapshot_identifier == null ? module.rds_postgres_master.db_instance_username : var.instance.spec.snapshot_username
      password = local.snapshot_identifier == null ? module.postgres_password.result : var.instance.spec.snapshot_password
      port     = module.rds_postgres_replica["replica-${index}"].db_instance_port
    }
  } : {}

  output_interfaces = {
    "writer" = {
      host              = local.writer_hostname
      username          = local.snapshot_identifier == null ? module.rds_postgres_master.db_instance_username : var.instance.spec.snapshot_username
      password          = local.snapshot_identifier == null ? module.postgres_password.result : var.instance.spec.snapshot_password
      port              = module.rds_postgres_master.db_instance_port
      connection_string = sensitive("postgresql://${module.rds_postgres_master.db_instance_username}:${module.postgres_password.result}@${local.writer_hostname}:${module.rds_postgres_master.db_instance_port}/")
      name              = "writer"
      secrets           = ["password", "connection_string"]
    }
    "reader" = local.reader_count > 0 ? {
      host              = split(":", module.rds_postgres_replica["replica-0"].db_instance_endpoint)[0]
      username          = local.snapshot_identifier == null ? module.rds_postgres_master.db_instance_username : var.instance.spec.snapshot_username
      password          = local.snapshot_identifier == null ? module.postgres_password.result : var.instance.spec.snapshot_password
      port              = module.rds_postgres_replica["replica-0"].db_instance_port
      connection_string = sensitive("postgresql://${module.rds_postgres_master.db_instance_username}:${module.postgres_password.result}@${split(":", module.rds_postgres_replica["replica-0"].db_instance_endpoint)[0]}:${module.rds_postgres_replica["replica-0"].db_instance_port}/")
      secrets           = ["password", "connection_string"]
      name              = "reader"
      } : {
      host              = local.writer_hostname
      username          = local.snapshot_identifier == null ? module.rds_postgres_master.db_instance_username : var.instance.spec.snapshot_username
      password          = local.snapshot_identifier == null ? module.postgres_password.result : var.instance.spec.snapshot_password
      port              = module.rds_postgres_master.db_instance_port
      connection_string = sensitive("postgresql://${module.rds_postgres_master.db_instance_username}:${module.postgres_password.result}@${local.writer_hostname}:${module.rds_postgres_master.db_instance_port}/")
      secrets           = ["password", "connection_string"]
      name              = "writer"
    }
  }

  output_attributes = {
    resource_type = "postgres"
    resource_name = var.instance_name
    instances     = merge(local.writer_dbs, local.reader_dbs)
    secrets       = ["instances"]
  }
}

output "instances" {
  value = tomap(merge(local.writer_dbs, local.reader_dbs))
  # sensitive = true
}

# For old module compatibility

output "writer_host" {
  value = local.writer_hostname
}
output "writer_port" {
  value = module.rds_postgres_master.db_instance_port
}
output "writer_username" {
  value = module.rds_postgres_master.db_instance_username
  # sensitive = true
}
output "writer_password" {
  value = module.postgres_password.result
  # sensitive = true
}
output "writer_connection_string" {
  value = "postgresql://${local.writer_hostname}:${module.rds_postgres_master.db_instance_port}/"
}
output "reader_host" {
  value = local.reader_count > 0 ? split(":", module.rds_postgres_replica["replica-0"].db_instance_endpoint)[0] : null
}
output "reader_port" {
  value = local.reader_count > 0 ? module.rds_postgres_replica["replica-0"].db_instance_port : null
}
output "reader_username" {
  value = local.reader_count > 0 ? module.rds_postgres_replica["replica-0"].db_instance_username : null
  # sensitive = true
}
output "reader_password" {
  value = local.reader_count > 0 ? module.rds_postgres_replica["replica-0"].db_instance_master_user_secret_arn : null
  # sensitive = true
}
