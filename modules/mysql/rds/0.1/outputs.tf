locals {
  writer_hostname = split(":", module.rds-mysql-master.db_instance_endpoint)[0]
  #  reader_hostname = split(":", module.rds-mysql-replica["replica-0"].db_instance_endpoint)[0]
  writer_dbs = {
    "writer-0" = {
      name     = module.rds-mysql-master.db_instance_id
      host     = local.writer_hostname
      username = module.rds-mysql-master.db_instance_username
      password = module.rds-mysql-master.db_instance_password
      port     = module.rds-mysql-master.db_instance_port
    }
  }

  reader_dbs = local.reader_count > 0 ? {
    for index in range(local.reader_count) :
    "reader-${index}" => {
      name     = module.rds-mysql-replica["replica-${index}"].db_instance_id
      host     = split(":", module.rds-mysql-replica["replica-${index}"].db_instance_endpoint)[0]
      username = module.rds-mysql-replica["replica-${index}"].db_instance_username
      password = module.rds-mysql-replica["replica-${index}"].db_instance_password
      port     = module.rds-mysql-replica["replica-${index}"].db_instance_port
    }
  } : {}

  output_interfaces = {
    "writer" = {
      host              = local.writer_hostname
      username          = module.rds-mysql-master.db_instance_username
      password          = sensitive(module.rds-mysql-master.db_instance_password)
      port              = module.rds-mysql-master.db_instance_port
      connection_string = sensitive("mysql://${module.rds-mysql-master.db_instance_username}:${module.rds-mysql-master.db_instance_password}@${local.writer_hostname}:${module.rds-mysql-master.db_instance_port}/")
      name              = "writer"
      secrets           = ["password", "connection_string"]
    }
    "reader" = local.reader_count > 0 ? {
      host              = split(":", module.rds-mysql-replica["replica-0"].db_instance_endpoint)[0]
      username          = module.rds-mysql-replica["replica-0"].db_instance_username
      password          = sensitive(module.rds-mysql-replica["replica-0"].db_instance_password)
      port              = module.rds-mysql-replica["replica-0"].db_instance_port
      connection_string = sensitive("mysql://${module.rds-mysql-master.db_instance_username}:${module.rds-mysql-master.db_instance_password}@${split(":", module.rds-mysql-replica["replica-0"].db_instance_endpoint)[0]}:${module.rds-mysql-replica["replica-0"].db_instance_port}/")
      secrets           = ["password", "connection_string"]
      name              = "reader"
      } : {
      host              = local.writer_hostname
      username          = module.rds-mysql-master.db_instance_username
      password          = sensitive(module.rds-mysql-master.db_instance_password)
      port              = module.rds-mysql-master.db_instance_port
      connection_string = sensitive("mysql://${module.rds-mysql-master.db_instance_username}:${module.rds-mysql-master.db_instance_password}@${local.writer_hostname}:${module.rds-mysql-master.db_instance_port}/")
      secrets           = ["password", "connection_string"]
      name              = "writer"
    }
  }

  output_attributes = {
    resource_type = "mysql"
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
  value = module.rds-mysql-master.db_instance_port
}
output "writer_username" {
  value = module.rds-mysql-master.db_instance_username
  # sensitive = true
}
output "writer_password" {
  value = module.rds-mysql-master.db_instance_password
  # sensitive = true
}
output "writer_connection_string" {
  value = "mysql://${local.writer_hostname}:${module.rds-mysql-master.db_instance_port}/"
}
output "reader_host" {
  value = local.reader_count > 0 ? split(":", module.rds-mysql-replica["replica-0"].db_instance_endpoint)[0] : null
}
output "reader_port" {
  value = local.reader_count > 0 ? module.rds-mysql-replica["replica-0"].db_instance_port : null
}
output "reader_username" {
  value = local.reader_count > 0 ? module.rds-mysql-replica["replica-0"].db_instance_username : null
  # sensitive = true
}
output "reader_password" {
  value = local.reader_count > 0 ? module.rds-mysql-replica["replica-0"].db_instance_password : null
  # sensitive = true
}
