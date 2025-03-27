locals {
  spec = lookup(var.instance, "spec", {})
  size = lookup(local.spec, "size", {})

  advanced_security_options_lookup = lookup(local.spec, "advanced_security_options", { "anonymous_auth_enabled" : false, "enabled" : true })
  master_user_options_lookup       = lookup(local.advanced_security_options_lookup, "master_user_options", {})
  authenticated                    = lookup(lookup(local.spec, "advanced_security_options", {}), "authenticated", false)
  auth_type                        = lookup(lookup(local.spec, "advanced_security_options", {}), "auth_type", "basic_auth")
  autogenerate_master_password     = lookup(lookup(lookup(local.spec, "advanced_security_options", {}), "master_user_options", {}), "autogenerate_master_password", false)

  master_user_name     = lookup(local.master_user_options_lookup, "master_user_name", null)
  master_user_password = local.autogenerate_master_password ? module.master-password.0.result : lookup(lookup(local.master_user_options_lookup, "master_user_options", {}), "master_user_name", null)

  advanced_security_options = {
    enabled                        = lookup(local.advanced_security_options_lookup, "enabled", true)
    anonymous_auth_enabled         = lookup(local.advanced_security_options_lookup, "anonymous_auth_enabled", local.authenticated ? true : false)
    internal_user_database_enabled = lookup(local.advanced_security_options_lookup, "internal_user_database_enabled", lookup(local.master_user_options_lookup, "master_user_arn", null) != null ? true : false)
    master_user_options = {
      master_user_arn      = lookup(local.master_user_options_lookup, "master_user_arn", null)
      master_user_name     = local.master_user_name
      master_user_password = local.master_user_password
    }
  }

  cluster_config_lookup = lookup(local.spec, "cluster_config", {})
  cluster_config = merge(
    local.cluster_config_lookup,
    {
      instance_type  = local.size.instance
      instance_count = local.size.instance_count
    }
  )

  aws_cognito_details = lookup(lookup(var.inputs, "cognito_details", {}), "attributes", lookup(local.spec, "cognito_options", {}))
  cognito_options = {
    enabled          = length(local.aws_cognito_details) > 0 ? true : false
    identity_pool_id = lookup(local.aws_cognito_details, "identity_pool_id", null)
    role_arn         = lookup(local.aws_cognito_details, "role_arn", null)
    user_pool_id     = lookup(local.aws_cognito_details, "user_pool_id", null)
  }

  ebs_options_lookup = lookup(local.spec, "ebs_options", { "ebs_enabled" : true, "volume_size" : 64, "volume_type" : "gp3" })
  ebs_options = {
    ebs_enabled = lookup(local.ebs_options_lookup, "ebs_enabled", true)
    volume_size = lookup(local.ebs_options_lookup, "volume_size", local.size.volume)
    volume_type = lookup(local.ebs_options_lookup, "volume_type", "gp3")
    iops        = lookup(local.ebs_options_lookup, "iops", null)
    throughput  = lookup(local.ebs_options_lookup, "throughput", null)
  }

  default_sg_rule = {
    type      = "ingress"
    cidr_ipv4 = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_cidr
  }
  security_group_rules = merge(
    lookup(local.spec, "security_group_rules", {}),
    {
      default_rule = local.default_sg_rule
    }
  )

  vpc_options_lookup = lookup(local.spec, "vpc_options", {})
  vpc_options = {
    subnet_ids         = lookup(local.vpc_options_lookup, "subnet_ids", lookup(local.spec, "private", true) ? var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnets : var.inputs.network_details.attributes.legacy_outputs.vpc_details.public_subnets)
    security_group_ids = lookup(local.vpc_options_lookup, "security_group_ids", [])
  }
}
