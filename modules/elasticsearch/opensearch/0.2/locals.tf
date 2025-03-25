locals {
  spec = lookup(var.instance, "spec", {})
  size = lookup(local.spec, "size", {})

  advanced_security_options_lookup = lookup(local.spec, "advanced_security_options", { "anonymous_auth_enabled" : false, "enabled" : true })
  authenticated                    = lookup(lookup(local.spec, "advanced_security_options", {}), "authenticated", false)
  autogenerate_master_password     = lookup(lookup(local.spec, "advanced_security_options", {}), "autogenerate_master_password", false)

  advanced_security_options = {
    enabled                        = true
    anonymous_auth_enabled         = local.authenticated ? true : false
    internal_user_database_enabled = lookup(local.advanced_security_options_lookup, "master_user_arn", null) != null ? true : false
    master_user_options = {
      master_user_arn      = lookup(local.advanced_security_options_lookup, "master_user_arn", null)
      master_user_name     = lookup(local.advanced_security_options_lookup, "master_user_name", null)
      master_user_password = local.autogenerate_master_password ? module.master-password.result : lookup(lookup(local.advanced_security_options_lookup, "master_user_options", {}), "master_user_name", null)
    }
  }

  aws_cognito_details = lookup(var.inputs.cognito_details, "attributes", {})
}
