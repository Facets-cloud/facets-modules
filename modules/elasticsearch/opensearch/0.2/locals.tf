locals {
  spec = lookup(var.instance, "spec", {})
  size = lookup(local.spec, "size", {})

  advanced_security_options_lookup  = lookup(local.spec, "advanced_security_options", {})
  advanced_security_options_enabled = lookup(local.advanced_security_options_lookup, "enabled", true)
  master_user_options_lookup        = lookup(local.advanced_security_options_lookup, "master_user_options", {})
  auth_type                         = lookup(lookup(local.spec, "advanced_security_options", {}), "auth_type", "basic_auth")
  autogenerate_master_password      = lookup(lookup(lookup(local.spec, "advanced_security_options", {}), "master_user_options", {}), "autogenerate_master_password", false)

  master_user_name     = lookup(local.master_user_options_lookup, "master_user_name", null)
  master_user_password = local.autogenerate_master_password ? random_password.master-password.0.result : lookup(lookup(local.master_user_options_lookup, "master_user_options", {}), "master_user_name", null)

  advanced_security_options = {
    enabled                        = local.advanced_security_options_enabled
    anonymous_auth_enabled         = lookup(local.advanced_security_options_lookup, "anonymous_auth_enabled", false)
    internal_user_database_enabled = lookup(local.advanced_security_options_lookup, "internal_user_database_enabled", lookup(local.master_user_options_lookup, "master_user_arn", null) == null ? true : false)
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
  cognito_options = length(local.aws_cognito_details) > 0 ? {
    enabled          = true
    identity_pool_id = lookup(local.aws_cognito_details, "identity_pool_id", null)
    role_arn         = lookup(local.aws_cognito_details, "role_arn", null)
    user_pool_id     = lookup(local.aws_cognito_details, "user_pool_id", null)
  } : {}

  ebs_options_lookup = lookup(local.spec, "ebs_options", { "ebs_enabled" : true, "volume_size" : 64, "volume_type" : "gp3" })
  ebs_options = {
    ebs_enabled = lookup(local.ebs_options_lookup, "ebs_enabled", true)
    volume_size = lookup(local.ebs_options_lookup, "volume_size", local.size.volume)
    volume_type = lookup(local.ebs_options_lookup, "volume_type", "gp3")
    iops        = lookup(local.ebs_options_lookup, "iops", null)
    throughput  = lookup(local.ebs_options_lookup, "throughput", null)
  }

  security_group_rules = merge(
    lookup(local.spec, "security_group_rules", {}),
    {
      ingress_443 = {
        type        = "ingress"
        description = "HTTPS access from VPC"
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_cidr
      }
    }
  )

  vpc_options_lookup = lookup(local.spec, "vpc_options", {})
  vpc_options = lookup(local.spec, "private", true) ? {
    subnet_ids         = lookup(local.vpc_options_lookup, "subnet_ids", var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnets)
    security_group_ids = lookup(local.vpc_options_lookup, "security_group_ids", [])
  } : {}
}
