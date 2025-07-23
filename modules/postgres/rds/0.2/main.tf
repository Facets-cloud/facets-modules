
locals {
  snapshot_identifier = lookup(local.spec, "use_snapshot", false) ? lookup(var.instance.spec, "snapshot_identifier", lookup(local.advanced_rds_postgres, "snapshot_identifier", null)) : null
  instance_size       = lookup(var.instance.spec, "size", {})
  reader_count        = lookup(local.instance_size, "reader", {}) == {} ? 0 : lookup(lookup(var.instance.spec.size, "reader", {}), "replica_count", lookup(lookup(local.instance_size, "reader", {}), "instance_count", 0))
  reader_db_instances = local.reader_count > 0 ? {
    for index in range(local.reader_count) :
    "replica-${index}" => {
      instance_class = lookup(lookup(local.instance_size, "reader", {}), "instance")
    }
  } : {}
  writer_db_instances = {
    "master" = {
      instance_class = lookup(lookup(local.instance_size, "writer", {}), "instance")
    }
  }
  advanced              = lookup(lookup(var.instance, "advanced", {}), "rds", {})
  advanced_rds_postgres = lookup(local.advanced, "rds-postgres", {})
  username              = lookup(local.advanced_rds_postgres, "username", "root")
  db_names              = lookup(var.instance.spec, "db_names", [])
  db_schemas            = lookup(var.instance.spec, "db_schemas", {})
  metadata              = lookup(var.instance, "metadata", {})
  user_defined_tags     = lookup(local.metadata, "tags", {})
  tags                  = merge(local.user_defined_tags, var.environment.cloud_tags)
  iops                  = local.storage_type == "gp2" ? null : local.storage_type == "gp3" && local.allocated_storage < 400 ? null : lookup(local.advanced_rds_postgres, "iops", 12000) < 12000 ? 12000 : lookup(local.advanced_rds_postgres, "iops", 12000)
  allocated_storage     = lookup(local.advanced_rds_postgres, "allocated_storage", 50)
  storage_type          = lookup(local.advanced_rds_postgres, "storage_type", "gp3")
  max_allocated_storage = lookup(local.advanced_rds_postgres, "max_allocated_storage", 200)
  multi_az              = lookup(local.advanced_rds_postgres, "multi_az", false)
  availability_zone     = local.multi_az ? null : lookup(local.advanced_rds_postgres, "availability_zone", null) == null ? var.inputs.network_details.attributes.legacy_outputs.vpc_details.azs[0] : lookup(local.advanced_rds_postgres, "availability_zone", null)

  max_connections             = lookup(var.instance.spec, "max_connections", {})
  spec_reader_max_connections = lookup(local.max_connections, "reader", null)
  reader_max_connections = local.spec_reader_max_connections != null ? {
    "max_connections" : {
      name         = "max_connections"
      value        = local.spec_reader_max_connections
      apply_method = "pending-reboot"
    }
  } : {}

  spec_writer_max_connections = lookup(local.max_connections, "writer", null)
  writer_max_connections = local.spec_writer_max_connections != null ? {
    "max_connections" : {
      name         = "max_connections"
      value        = local.spec_writer_max_connections
      apply_method = "pending-reboot"
    }
  } : {}

  parameters             = lookup(local.advanced_rds_postgres, "parameters", {})
  reader_parameters      = [for param_name, param_attributes in merge(lookup(local.parameters, "reader", {}), local.reader_max_connections) : { name = param_name, value = lookup(param_attributes, "value"), apply_method = lookup(param_attributes, "apply_method", "immediate") }]
  writer_parameters      = [for param_name, param_attributes in merge(lookup(local.parameters, "writer", {}), local.writer_max_connections) : { name = param_name, value = lookup(param_attributes, "value"), apply_method = lookup(param_attributes, "apply_method", "immediate") }]
  vpc_security_group_ids = lookup(local.advanced_rds_postgres, "vpc_security_group_ids", [])
  version                = lookup(var.instance.spec, "postgres_version", null)
  family                 = "postgres${split(".", local.version)[0]}"

  peering_definitions = fileset("../../../../stacks/${var.cluster.stackName}/additional_peering/instances", "*.json")
  peered_cidrs = [
    for def in local.peering_definitions :
    jsondecode(file("../../../../stacks/${var.cluster.stackName}/additional_peering/instances/${def}"))["cidr"]
  ]
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 30
  globally_unique = true
  resource_name   = var.instance_name
  resource_type   = "postgres"
  is_k8s          = false
}

module "postgres_password" {
  source = "github.com/Facets-cloud/facets-utility-modules//password"
  length = 20
}

resource "aws_security_group" "allow_postgres" {
  name        = module.name.name
  description = "Postgres security group for ${module.name.name}"
  vpc_id      = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  tags = merge(
    {
      "Name" = format("%s", module.name.name)
    },
    local.tags,
  )
  timeouts {
    create = "10m"
    delete = "15m"
  }
}

resource "aws_security_group_rule" "computed_ingress_with_cidr_blocks" {

  security_group_id = aws_security_group.allow_postgres.id
  type              = "ingress"
  cidr_blocks       = distinct(concat(local.peered_cidrs, [var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_cidr]))
  description       = "Postgres access from within VPC since db is private"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
}


module "rds_postgres_master" {
  source                                = "./terraform-aws-rds-master"
  identifier                            = "${module.name.name}-writer"
  engine                                = "postgres"
  engine_version                        = local.version
  family                                = local.family
  major_engine_version                  = local.version
  instance_class                        = lookup(local.writer_db_instances.master, "instance_class", "db.t4g.medium")
  allocated_storage                     = local.allocated_storage
  max_allocated_storage                 = local.max_allocated_storage
  storage_type                          = local.storage_type
  storage_encrypted                     = lookup(local.advanced_rds_postgres, "storage_encrypted", true)
  iops                                  = local.iops
  db_name                               = lookup(local.advanced_rds_postgres, "db_name", "")
  username                              = local.username
  manage_master_user_password           = false
  password                              = module.postgres_password.result
  port                                  = 5432
  multi_az                              = local.multi_az
  availability_zone                     = local.availability_zone
  vpc_security_group_ids                = concat(local.vpc_security_group_ids, [aws_security_group.allow_postgres.id])
  subnet_ids                            = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_objects.id
  create_db_subnet_group                = true
  domain_iam_role_name                  = lookup(local.advanced_rds_postgres, "domain_iam_role_name", null)
  maintenance_window                    = lookup(local.advanced_rds_postgres, "maintenance_window", "sun:01:00-sun:02:00")
  backup_window                         = lookup(local.advanced_rds_postgres, "backup_window", "03:00-06:00")
  snapshot_identifier                   = local.snapshot_identifier
  enabled_cloudwatch_logs_exports       = lookup(local.advanced_rds_postgres, "enabled_cloudwatch_logs_exports", ["postgresql", "upgrade"])
  create_cloudwatch_log_group           = lookup(local.advanced_rds_postgres, "create_cloudwatch_log_group", true)
  backup_retention_period               = lookup(local.advanced_rds_postgres, "backup_retention_period", 1)
  skip_final_snapshot                   = lookup(local.advanced_rds_postgres, "skip_final_snapshot", true)
  deletion_protection                   = lookup(local.advanced_rds_postgres, "deletion_protection", false)
  performance_insights_enabled          = lookup(local.advanced_rds_postgres, "performance_insights_enabled", false)
  performance_insights_retention_period = lookup(local.advanced_rds_postgres, "performance_insights_retention_period", 7)
  create_monitoring_role                = true
  monitoring_interval                   = lookup(local.advanced_rds_postgres, "monitoring_interval", 10)
  monitoring_role_name                  = "${module.name.name}-writer-monitoring-role"
  monitoring_role_use_name_prefix       = lookup(local.advanced_rds_postgres, "monitoring_role_use_name_prefix", false)
  monitoring_role_description           = "Monitoring role for ${module.name.name}-master"
  tags                                  = local.tags
  db_instance_tags                      = lookup(local.advanced_rds_postgres, "db_instance_tags", {})
  options                               = lookup(local.advanced_rds_postgres, "options", [])
  parameter_group_use_name_prefix       = false
  parameter_group_name                  = lookup(local.advanced_rds_postgres, "parameter_group_name", null)
  parameters                            = local.writer_parameters
  db_option_group_tags                  = lookup(local.advanced_rds_postgres, "db_option_group_tags", {})
  db_parameter_group_tags               = lookup(local.advanced_rds_postgres, "db_parameter_group_tags", {})
  apply_immediately                     = lookup(var.instance.spec, "apply_immediately", false)
  timeouts = {
    create = "120m"
    delete = "60m"
    update = "60m"
  }
}

module "rds_postgres_replica" {
  for_each                              = local.reader_db_instances
  source                                = "./terraform-aws-rds-master"
  identifier                            = "${module.name.name}-${each.key}"
  engine                                = "postgres"
  engine_version                        = local.version
  family                                = local.family
  major_engine_version                  = local.version
  instance_class                        = lookup(local.reader_db_instances["${each.key}"], "instance_class", "db.t4g.medium")
  allocated_storage                     = local.allocated_storage
  max_allocated_storage                 = local.max_allocated_storage
  storage_type                          = local.storage_type
  storage_encrypted                     = lookup(local.advanced_rds_postgres, "storage_encrypted", true)
  iops                                  = local.iops
  replicate_source_db                   = module.rds_postgres_master.db_instance_identifier
  port                                  = 5432
  multi_az                              = local.multi_az
  availability_zone                     = local.availability_zone
  vpc_security_group_ids                = concat(local.vpc_security_group_ids, [aws_security_group.allow_postgres.id])
  subnet_ids                            = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_objects.id
  create_db_subnet_group                = false
  domain_iam_role_name                  = lookup(local.advanced_rds_postgres, "domain_iam_role_name", null)
  maintenance_window                    = lookup(local.advanced_rds_postgres, "maintenance_window", "sun:01:00-sun:02:00")
  enabled_cloudwatch_logs_exports       = lookup(local.advanced_rds_postgres, "enabled_cloudwatch_logs_exports", ["postgresql", "upgrade"])
  create_cloudwatch_log_group           = lookup(local.advanced_rds_postgres, "create_cloudwatch_log_group", true)
  skip_final_snapshot                   = lookup(local.advanced_rds_postgres, "skip_final_snapshot", true)
  deletion_protection                   = lookup(local.advanced_rds_postgres, "deletion_protection", false)
  performance_insights_enabled          = lookup(local.advanced_rds_postgres, "performance_insights_enabled", false)
  performance_insights_retention_period = lookup(local.advanced_rds_postgres, "performance_insights_retention_period", 7)
  create_monitoring_role                = true
  monitoring_interval                   = lookup(local.advanced_rds_postgres, "monitoring_interval", 10)
  monitoring_role_name                  = "${module.name.name}-reader-${each.key}-monitoring-role"
  monitoring_role_use_name_prefix       = lookup(local.advanced_rds_postgres, "monitoring_role_use_name_prefix", false)
  monitoring_role_description           = "Monitoring role for ${module.name.name}-master"
  tags                                  = local.tags
  db_instance_tags                      = lookup(local.advanced_rds_postgres, "db_instance_tags", {})
  options                               = lookup(local.advanced_rds_postgres, "options", [])
  parameter_group_use_name_prefix       = false
  parameter_group_name                  = lookup(local.advanced_rds_postgres, "parameter_group_name", null)
  parameters                            = local.reader_parameters
  db_option_group_tags                  = lookup(local.advanced_rds_postgres, "db_option_group_tags", {})
  db_parameter_group_tags               = lookup(local.advanced_rds_postgres, "db_parameter_group_tags", {})
  apply_immediately                     = lookup(var.instance.spec, "apply_immediately", false)
  timeouts = {
    create = "120m"
    delete = "60m"
    update = "60m"
  }
}

module "pg_database" {
  count       = length(local.db_names) == 0 ? 0 : 1
  source      = "github.com/Facets-cloud/facets-utility-modules//postgres_database"
  depends_on  = [module.rds_postgres_master]
  name        = "${module.name.name}-postgres-job"
  namespace   = var.environment.namespace
  environment = var.environment
  password    = module.postgres_password.result
  host        = split(":", module.rds_postgres_master.db_instance_endpoint)[0]
  username    = local.username
  db_names    = local.db_names
  db_schemas  = local.db_schemas
  tolerations = lookup(local.advanced_rds_postgres, "job_tolerations", [])
  inputs      = var.inputs
}
