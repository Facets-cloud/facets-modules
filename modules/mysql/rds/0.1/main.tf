locals {
  reader_count = lookup(var.instance.spec.size, "reader", {}) == {} ? 0 : lookup(lookup(var.instance.spec.size, "reader", {}), "replica_count", lookup(lookup(var.instance.spec.size, "reader", {}), "instance_count", 0))
  reader_db_instances = local.reader_count > 0 ? {
    for index in range(local.reader_count) :
    "replica-${index}" => {
      instance_class = var.instance.spec.size.reader.instance
    }
  } : {}
  writer_db_instances = {
    "master" = {
      instance_class = var.instance.spec.size.writer.instance
    }
  }
  db_cluster_name = length(lower("${var.environment.unique_name}-${var.instance_name}")) >= 30 ? substr("fc-${md5(lower("${var.environment.unique_name}-${var.instance_name}"))}", 0, 20) : lower("${var.environment.unique_name}-${var.instance_name}")

  advanced           = lookup(lookup(var.instance, "advanced", {}), "rds", {})
  advanced_rds_mysql = lookup(local.advanced, "rds-mysql", {})

  version               = lookup(var.instance.spec, "mysql_version", null)
  metadata              = lookup(var.instance, "metadata", {})
  user_defined_tags     = lookup(local.metadata, "tags", {})
  iops                  = local.storage_type == "gp2" ? null : local.storage_type == "gp3" && local.allocated_storage < 400 ? null : lookup(local.advanced_rds_mysql, "iops", 12000) < 12000 ? 12000 : lookup(local.advanced_rds_mysql, "iops", 12000)
  tags                  = merge(local.user_defined_tags, var.environment.cloud_tags)
  multi_az              = lookup(local.advanced_rds_mysql, "multi_az", false)
  storage_type          = lookup(local.advanced_rds_mysql, "storage_type", "gp3")
  allocated_storage     = lookup(local.advanced_rds_mysql, "allocated_storage", 50)
  max_allocated_storage = lookup(local.advanced_rds_mysql, "max_allocated_storage", 200)
  availability_zone     = lookup(local.advanced_rds_mysql, "availability_zone", null) == null ? var.inputs.network_details.attributes.legacy_outputs.vpc_details.azs[0] : lookup(local.advanced_rds_mysql, "availability_zone", null)
  snapshot              = lookup(local.advanced_rds_mysql, "snapshot_identifier", null) != null ? true : false

  max_connections                   = lookup(var.instance.spec, "max_connections", {})
  db_parameter_group_parameters     = lookup(local.advanced_rds_mysql, "parameters", [])
  db_parameter_group_parameters_map = { for param in local.db_parameter_group_parameters : param.name => param }
  reader_db_parameter_group_parameters_map = lookup(local.max_connections, "reader", null) == null ? local.db_parameter_group_parameters_map : merge(local.db_parameter_group_parameters_map, {
    max_connections = {
      name  = "max_connections"
      value = lookup(local.max_connections, "reader")
    }
  })
  writer_db_parameter_group_parameters_map = lookup(local.max_connections, "writer", null) == null ? local.db_parameter_group_parameters_map : merge(local.db_parameter_group_parameters_map, {
    max_connections = {
      name  = "max_connections"
      value = lookup(local.max_connections, "writer")
    }
  })
  reader_db_parameter_group_parameters = [
    for k, v in local.reader_db_parameter_group_parameters_map : v
  ]
  writer_db_parameter_group_parameters = [
    for k, v in local.writer_db_parameter_group_parameters_map : v
  ]
}

module "mysql-password" {
  source = "github.com/Facets-cloud/facets-utility-modules//password"
  length = 20
}

module "mysql_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.db_cluster_name
  description = "MySQL security group for ${local.db_cluster_name}"
  vpc_id      = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC since db is private"
      cidr_blocks = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_cidr
    },
  ]

  tags = local.tags
}

module "rds-mysql-master" {
  source                                = "./terraform-aws-rds-master"
  identifier                            = "${local.db_cluster_name}-writer"
  instance_class                        = lookup(local.writer_db_instances.master, "instance_class", "db.t4g.medium")
  engine                                = "mysql"
  engine_version                        = local.version
  db_name                               = lookup(local.advanced_rds_mysql, "db_name", "")
  family                                = "mysql${local.version}"
  subnet_ids                            = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_objects.id
  major_engine_version                  = local.version
  storage_encrypted                     = lookup(local.advanced_rds_mysql, "storage_encrypted", true)
  allocated_storage                     = local.allocated_storage
  max_allocated_storage                 = local.max_allocated_storage
  storage_type                          = local.storage_type
  iops                                  = local.iops
  username                              = lookup(local.advanced_rds_mysql, "username", "root")
  monitoring_interval                   = lookup(local.advanced_rds_mysql, "monitoring_interval", 10)
  password                              = module.mysql-password.result
  port                                  = 3306
  create_db_subnet_group                = true
  multi_az                              = local.multi_az
  availability_zone                     = local.availability_zone
  domain_iam_role_name                  = lookup(local.advanced_rds_mysql, "domain_iam_role_name", null)
  vpc_security_group_ids                = [module.mysql_security_group.security_group_id]
  monitoring_role_name                  = "${local.db_cluster_name}-writer-monitoring-role"
  create_monitoring_role                = true
  backup_retention_period               = lookup(local.advanced_rds_mysql, "backup_retention_period", 1)
  deletion_protection                   = lookup(local.advanced_rds_mysql, "deletion_protection", false)
  skip_final_snapshot                   = lookup(local.advanced_rds_mysql, "skip_final_snapshot", true)
  maintenance_window                    = lookup(local.advanced_rds_mysql, "maintenance_window", "sun:01:00-sun:02:00")
  backup_window                         = lookup(local.advanced_rds_mysql, "backup_window", "03:00-06:00")
  snapshot_identifier                   = lookup(local.advanced_rds_mysql, "snapshot_identifier", null)
  s3_import                             = lookup(local.advanced_rds_mysql, "s3_import", null)
  tags                                  = local.tags
  db_instance_tags                      = lookup(local.advanced_rds_mysql, "db_instance_tags", {})
  options                               = lookup(local.advanced_rds_mysql, "options", [])
  enabled_cloudwatch_logs_exports       = lookup(local.advanced_rds_mysql, "enabled_cloudwatch_logs_exports", ["general"])
  performance_insights_enabled          = lookup(local.advanced_rds_mysql, "performance_insights_enabled", false)
  performance_insights_retention_period = lookup(local.advanced_rds_mysql, "performance_insights_retention_period", 7)
  create_random_password                = false
  create_cloudwatch_log_group           = lookup(local.advanced_rds_mysql, "create_cloudwatch_log_group", true)
  parameters                            = local.writer_db_parameter_group_parameters
  parameter_group_name                  = lookup(local.advanced_rds_mysql, "parameter_group_name", null)
  apply_immediately                     = lookup(var.instance.spec, "apply_immediately", false)
  timeouts = {
    create = "120m"
    delete = "60m"
    update = "60m"
  }
}

module "rds-mysql-replica" {
  for_each             = local.reader_db_instances
  replicate_source_db  = module.rds-mysql-master.db_instance_id
  source               = "./terraform-aws-rds-master"
  identifier           = "${local.db_cluster_name}-${each.key}"
  instance_class       = lookup(local.reader_db_instances["${each.key}"], "instance_class", "db.t4g.medium")
  engine               = "mysql"
  engine_version       = local.version
  family               = "mysql${local.version}"
  subnet_ids           = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_objects.id
  major_engine_version = local.version
  storage_encrypted    = lookup(local.advanced_rds_mysql, "storage_encrypted", true)
  iops                 = local.iops
  # allocated_storage                     = lookup(local.advanced_rds_mysql, "allocated_storage", 20)
  max_allocated_storage                 = local.max_allocated_storage
  storage_type                          = local.storage_type
  username                              = lookup(local.advanced_rds_mysql, "username", "root")
  monitoring_interval                   = lookup(local.advanced_rds_mysql, "monitoring_interval", 10)
  password                              = module.mysql-password.result
  port                                  = 3306
  create_db_subnet_group                = false
  multi_az                              = local.multi_az
  availability_zone                     = local.availability_zone
  domain_iam_role_name                  = lookup(local.advanced_rds_mysql, "domain_iam_role_name", null)
  vpc_security_group_ids                = [module.mysql_security_group.security_group_id]
  monitoring_role_name                  = "${local.db_cluster_name}-reader-${each.key}-monitoring-role"
  create_monitoring_role                = true
  backup_retention_period               = lookup(local.advanced_rds_mysql, "backup_retention_period", 0)
  deletion_protection                   = lookup(local.advanced_rds_mysql, "deletion_protection", false)
  skip_final_snapshot                   = lookup(local.advanced_rds_mysql, "skip_final_snapshot", true)
  maintenance_window                    = lookup(local.advanced_rds_mysql, "maintenance_window", "sun:01:00-sun:02:00")
  backup_window                         = lookup(local.advanced_rds_mysql, "backup_window", "03:00-06:00")
  snapshot_identifier                   = lookup(local.advanced_rds_mysql, "snapshot_identifier", null)
  s3_import                             = lookup(local.advanced_rds_mysql, "s3_import", null)
  tags                                  = local.tags
  db_instance_tags                      = lookup(local.advanced_rds_mysql, "db_instance_tags", {})
  options                               = lookup(local.advanced_rds_mysql, "options", [])
  enabled_cloudwatch_logs_exports       = lookup(local.advanced_rds_mysql, "enabled_cloudwatch_logs_exports", ["general"])
  performance_insights_enabled          = lookup(local.advanced_rds_mysql, "performance_insights_enabled", false)
  performance_insights_retention_period = lookup(local.advanced_rds_mysql, "performance_insights_retention_period", 7)
  create_random_password                = false
  create_cloudwatch_log_group           = lookup(local.advanced_rds_mysql, "create_cloudwatch_log_group", true)
  parameter_group_name                  = lookup(local.advanced_rds_mysql, "parameter_group_name", null)
  parameters                            = local.reader_db_parameter_group_parameters
  apply_immediately                     = lookup(var.instance.spec, "apply_immediately", false)
  timeouts = {
    create = "120m"
    delete = "60m"
    update = "60m"
  }
}



module "mysql-root-password" {
  source        = "./generate_resource_details"
  name          = "Basic Authentication Password for Mysql RDS"
  value         = module.mysql-password.result
  resource_type = "Databases"
  resource_name = local.db_cluster_name
  key           = "DB-Name: ${local.db_cluster_name}"
}
