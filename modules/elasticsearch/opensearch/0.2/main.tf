

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 28
  resource_name   = var.instance_name
  resource_type   = "lasticsearch"
  is_k8s          = false
  globally_unique = true
  prefix          = "e"
}

module "master-password" {
  count   = local.autogenerate_master_password ? 1 : 0
  source  = "github.com/Facets-cloud/facets-utility-modules//password"
  length  = 20
  special = true
}

module "opensearch" {
  source = "terraform-aws-opensearch-1.1.2"

  access_policies                         = lookup(local.spec, "access_policies", null)
  access_policy_override_policy_documents = lookup(local.spec, "access_policy_override_policy_documents", [])
  access_policy_source_policy_documents   = lookup(local.spec, "access_policy_source_policy_documents", [])
  access_policy_statements                = lookup(local.spec, "access_policy_statements", {})
  advanced_options                        = lookup(local.spec, "advanced_options", {})
  advanced_security_options               = local.advanced_security_options
  auto_tune_options                       = lookup(local.spec, "auto_tune_options", { "desired_state" : "ENABLED", "rollback_on_disable" : "NO_ROLLBACK" })
  cloudwatch_log_group_kms_key_id         = lookup(local.spec, "cloudwatch_log_group_kms_key_id", null)
  cloudwatch_log_group_retention_in_days  = lookup(local.spec, "cloudwatch_log_group_retention_in_days", 60)
  cloudwatch_log_resource_policy_name     = lookup(local.spec, "cloudwatch_log_resource_policy_name", null)
  cluster_config = merge(
    lookup(local.spec, "cluster_config", {}),
    {
      instance_type  = local.size.instance
      instance_count = local.size.instance_count
    }
  )
  cognito_options                       = lookup(local.spec, "cognito_options", {})
  create                                = lookup(local.spec, "create", true)
  create_access_policy                  = lookup(local.spec, "create_access_policy", true)
  create_cloudwatch_log_groups          = lookup(local.spec, "create_cloudwatch_log_groups", true)
  create_cloudwatch_log_resource_policy = lookup(local.spec, "create_cloudwatch_log_resource_policy", true)
  create_saml_options                   = lookup(local.spec, "create_saml_options", false)
  create_security_group                 = lookup(local.spec, "create_security_group", true)
  domain_endpoint_options               = lookup(local.spec, "domain_endpoint_options", { "enforce_https" : true, "tls_security_policy" : "Policy-Min-TLS-1-2-2019-07" })
  domain_name                           = module.name.name
  ebs_options                           = lookup(local.spec, "ebs_options", { "ebs_enabled" : true, "volume_size" : 64, "volume_type" : "gp3" })
  enable_access_policy                  = lookup(local.spec, "enable_access_policy", true)
  encrypt_at_rest                       = lookup(local.spec, "encrypt_at_rest", { "enabled" : true })
  engine_version                        = lookup(local.spec, "elasticsearch_version", null)
  log_publishing_options                = lookup(local.spec, "log_publishing_options", [{ "log_type" : "INDEX_SLOW_LOGS" }, { "log_type" : "SEARCH_SLOW_LOGS" }])
  node_to_node_encryption               = lookup(local.spec, "node_to_node_encryption", { "enabled" : true })
  off_peak_window_options               = lookup(local.spec, "off_peak_window_options", { "enabled" : true, "off_peak_window" : { "hours" : 7 } })
  outbound_connections                  = lookup(local.spec, "outbound_connections", {})
  package_associations                  = lookup(local.spec, "package_associations", {})
  saml_options                          = lookup(local.spec, "saml_options", {})
  security_group_description            = lookup(local.spec, "security_group_description", null)
  security_group_name                   = lookup(local.spec, "security_group_name", null)
  security_group_rules                  = lookup(local.spec, "security_group_rules", {})
  security_group_tags                   = merge(lookup(local.spec, "security_group_tags", {}), var.environment.cloud_tags)
  security_group_use_name_prefix        = lookup(local.spec, "security_group_use_name_prefix", {})
  software_update_options               = lookup(local.spec, "software_update_options", { "auto_software_update_enabled" : true })
  tags                                  = merge(lookup(local.spec, "tags", {}), var.environment.cloud_tags)
  vpc_endpoints                         = lookup(local.spec, "vpc_endpoints", {})
  vpc_options = lookup(local.spec, "vpc_options", {
    subnet_ids         = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnets
    security_group_ids = [aws_security_group.elasticsearch.id]
  })
}
