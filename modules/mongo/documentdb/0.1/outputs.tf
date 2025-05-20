locals {
  writer_instances = {
    "writer-0" = {
      username = module.docdb.master_username
      password = sensitive(module.docdb.master_password)
      host     = module.docdb.master_host
      port     = module.docdb.db_port
      name     = "writer-0"
      secrets  = ["password"]
    }
  }
  reader_instances = {
    for index in range(lookup(local.size, "instance_count", null)) :
    "reader-${index}" => {
      host     = "module.docdb.replicas_host-${index}"
      name     = "reader-${index}"
      password = sensitive(module.docdb.master_password)
      username = module.docdb.master_username
      port     = module.docdb.db_port
      secrets  = ["password"]
    }
  }
  output_attributes = {
    security_group = {
      security_group_arn  = module.docdb.security_group_arn
      security_group_id   = module.docdb.security_group_id
      security_group_name = module.docdb.security_group_name
    }
    resource_type = "mongo"
    resource_name = var.instance_name
    instances     = merge(local.writer_instances, local.reader_instances)
    secrets       = ["instances"]
  }
  output_interfaces = {
    cluster = {
      arn               = module.docdb.arn
      cluster_name      = module.docdb.cluster_name
      endpoint          = module.docdb.endpoint
      connection_string = sensitive("mongodb://${module.docdb.master_username}:${module.docdb.master_password}@${module.docdb.endpoint}:${module.docdb.db_port}")
      host              = module.docdb.master_host
      password          = sensitive(module.docdb.master_password)
      username          = module.docdb.master_username
      port              = module.docdb.db_port
      secrets           = ["password", "connection_string"]
    }
    reader = {
      host = module.docdb.reader_endpoint
    }
    instance = {
      host = module.docdb.replicas_host
    }
  }
}