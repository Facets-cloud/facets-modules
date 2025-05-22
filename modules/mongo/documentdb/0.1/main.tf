locals {
  spec                = lookup(var.instance, "spec", {})
  advanced            = lookup(lookup(var.instance, "advanced", {}), "documentdb", {})
  metadata            = lookup(var.instance, "metadata", {})
  user_defined_tags   = lookup(local.metadata, "tags", {})
  size                = lookup(local.spec, "size", {})
  version             = lookup(var.instance.spec, "documentdb_version", null)
  peering_definitions = fileset("../../../../stacks/${var.cluster.stackName}/additional_peering/instances", "*.json")
  peered_cidrs = [
    for def in local.peering_definitions :
    jsondecode(file("../../../../stacks/${var.cluster.stackName}/additional_peering/instances/${def}"))["cidr"]
  ]
  cluster_family = substr(local.version, 0, 3)
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_name   = var.instance_name
  resource_type   = "documentdb"
  limit           = 30
  environment     = var.environment
}

module "docdb" {
  source                          = "./terraform-aws-documentdb-cluster"
  subnet_ids                      = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_objects.id
  vpc_id                          = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  name                            = lookup(local.advanced, "name", module.name.name)
  allowed_cidr_blocks             = concat([var.cluster.vpcCIDR, lookup(var.cc_metadata, "cc_vpc_cidr", "127.0.0.1/32")], local.peered_cidrs)
  additional_tag_map              = lookup(local.advanced, "additional_tag_map", {})
  allow_ingress_from_self         = lookup(local.advanced, "allow_ingress_from_self", false)
  allowed_egress_cidr_blocks      = lookup(local.advanced, "allowed_egress_cidr_blocks", ["0.0.0.0/0"])
  allowed_security_groups         = lookup(local.advanced, "allowed_security_groups", [])
  apply_immediately               = lookup(local.advanced, "apply_immediately", true)
  attributes                      = lookup(local.advanced, "attributes", [])
  auto_minor_version_upgrade      = lookup(local.advanced, "auto_minor_version_upgrade", true)
  ca_cert_identifier              = lookup(local.advanced, "ca_cert_identifier", null)
  cluster_dns_name                = lookup(local.advanced, "cluster_dns_name", "")
  cluster_family                  = "docdb${local.cluster_family}"
  cluster_parameters              = lookup(local.advanced, "cluster_parameters", [])
  cluster_size                    = lookup(local.size, "instance_count", null)
  context                         = lookup(local.advanced, "context", { "additional_tag_map" : {}, "attributes" : [], "delimiter" : null, "descriptor_formats" : {}, "enabled" : true, "environment" : null, "id_length_limit" : null, "label_key_case" : null, "label_order" : [], "label_value_case" : null, "labels_as_tags" : ["unset"], "name" : null, "namespace" : null, "regex_replace_chars" : null, "stage" : null, "tags" : {}, "tenant" : null })
  db_port                         = lookup(local.advanced, "db_port", 27017)
  deletion_protection             = lookup(local.advanced, "deletion_protection", false)
  delimiter                       = lookup(local.advanced, "delimiter", null)
  descriptor_formats              = lookup(local.advanced, "descriptor_formats", {})
  egress_from_port                = lookup(local.advanced, "egress_from_port", 0)
  egress_protocol                 = lookup(local.advanced, "egress_protocol", "-1")
  egress_to_port                  = lookup(local.advanced, "egress_to_port", 0)
  enable_performance_insights     = lookup(local.advanced, "enable_performance_insights", false)
  enabled                         = lookup(local.advanced, "enabled", null)
  enabled_cloudwatch_logs_exports = lookup(local.advanced, "enabled_cloudwatch_logs_exports", [])
  engine                          = "docdb"
  engine_version                  = local.version
  environment                     = lookup(local.advanced, "environment", null)
  external_security_group_id_list = lookup(local.advanced, "external_security_group_id_list", [])
  id_length_limit                 = lookup(local.advanced, "id_length_limit", null)
  instance_class                  = lookup(local.size, "instance", null)
  kms_key_id                      = lookup(local.advanced, "kms_key_id", "")
  label_key_case                  = lookup(local.advanced, "label_key_case", null)
  label_order                     = lookup(local.advanced, "label_order", null)
  label_value_case                = lookup(local.advanced, "label_value_case", null)
  labels_as_tags                  = lookup(local.advanced, "labels_as_tags", ["default"])
  master_password                 = lookup(local.advanced, "master_password", "")
  master_username                 = lookup(local.advanced, "master_username", "admin1")
  namespace                       = lookup(local.advanced, "namespace", null)
  preferred_backup_window         = lookup(local.advanced, "preferred_backup_window", null)
  preferred_maintenance_window    = lookup(local.advanced, "preferred_maintenance_window", null)
  reader_dns_name                 = lookup(local.advanced, "reader_dns_name", "")
  regex_replace_chars             = lookup(local.advanced, "regex_replace_chars", null)
  retention_period                = lookup(local.advanced, "retention_period", 1)
  skip_final_snapshot             = lookup(local.advanced, "skip_final_snapshot", true)
  snapshot_identifier             = lookup(local.advanced, "snapshot_identifier", "")
  ssm_parameter_enabled           = lookup(local.advanced, "ssm_parameter_enabled", false)
  ssm_parameter_path_prefix       = lookup(local.advanced, "ssm_parameter_path_prefix", "/docdb/master-password/")
  stage                           = lookup(local.advanced, "stage", null)
  storage_encrypted               = lookup(local.advanced, "storage_encrypted", true)
  storage_type                    = lookup(local.advanced, "storage_type", "standard")
  tags                            = merge(local.user_defined_tags, var.environment.cloud_tags)
  tenant                          = lookup(local.advanced, "tenant", null)
  zone_id                         = lookup(local.advanced, "zone_id", "")
}
