data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


module "kms" {
  source                                 = "terraform-aws-kms-master"
  tags                                   = local.tags
  create_external                        = lookup(local.spec, "create_external", false)
  bypass_policy_lockout_safety_check     = lookup(local.spec, "bypass_policy_lockout_safety_check", null)
  customer_master_key_spec               = lookup(local.spec, "customer_master_key_spec", null)
  custom_key_store_id                    = lookup(local.spec, "custom_key_store_id", null)
  deletion_window_in_days                = lookup(local.spec, "deletion_window_in_days", 30)
  description                            = lookup(local.spec, "description", "Complete KMS key configurations with facets")
  enable_key_rotation                    = lookup(local.spec, "enable_key_rotation", true)
  is_enabled                             = lookup(local.spec, "is_enabled", true)
  key_material_base64                    = lookup(local.spec, "key_material_base64", null)
  key_usage                              = lookup(local.spec, "key_usage", null)
  multi_region                           = lookup(local.spec, "multi_region", false)
  policy                                 = lookup(local.spec, "policy", null)
  valid_to                               = lookup(local.spec, "valid_to", null)
  enable_default_policy                  = lookup(local.spec, "enable_default_policy", true)
  key_owners                             = lookup(local.spec, "key_owners", [])
  key_administrators                     = lookup(local.spec, "key_administrators", [])
  key_users                              = lookup(local.spec, "key_users", [])
  key_service_users                      = lookup(local.spec, "key_service_users", [])
  key_service_roles_for_autoscaling      = lookup(local.spec, "key_service_roles_for_autoscaling", [])
  key_symmetric_encryption_users         = lookup(local.spec, "key_symmetric_encryption_users", [])
  key_hmac_users                         = lookup(local.spec, "key_hmac_users", [])
  key_asymmetric_public_encryption_users = lookup(local.spec, "key_asymmetric_public_encryption_users", [])
  key_asymmetric_sign_verify_users       = lookup(local.spec, "key_asymmetric_sign_verify_users", [])
  key_statements                         = lookup(local.spec, "key_statements", {})
  source_policy_documents                = lookup(local.spec, "source_policy_documents", [])
  override_policy_documents              = lookup(local.spec, "override_policy_documents", [])
  enable_route53_dnssec                  = lookup(local.spec, "enable_route53_dnssec", false)
  route53_dnssec_sources                 = lookup(local.spec, "route53_dnssec_sources", [])
  rotation_period_in_days                = lookup(local.spec, "rotation_period_in_days", 90)
  create_replica                         = lookup(local.spec, "create_replica", false)
  primary_key_arn                        = lookup(local.spec, "primary_key_arn", null)
  create_replica_external                = lookup(local.spec, "create_replica_external", false)
  primary_external_key_arn               = lookup(local.spec, "primary_external_key_arn", null)
  aliases                                = lookup(local.spec, "aliases", [])
  computed_aliases                       = lookup(local.spec, "computed_aliases", {})
  aliases_use_name_prefix                = lookup(local.spec, "aliases_use_name_prefix", false)
  grants                                 = lookup(local.spec, "grants", {})
}
