locals {
  output_interfaces = {
    http = {
      connection_string = "https://${module.opensearch.domain_endpoint}"
      host              = module.opensearch.domain_endpoint
      username          = local.master_user_name
      password          = sensitive(local.master_user_password)
      secrets           = local.advanced_security_options_enabled && local.auth_type == "basic_auth" ? ["password"] : []
    }
    dashboard = {
      connection_string = "https://${module.opensearch.domain_dashboard_endpoint}"
      host              = module.opensearch.domain_dashboard_endpoint
      username          = local.master_user_name
      password          = sensitive(local.master_user_password)
      secrets           = local.advanced_security_options_enabled && local.auth_type == "basic_auth" ? ["password"] : []
    }
  }
  output_attributes = {
    resource_name = var.instance_name
    resource_type = "elasticsearch"
    instances = {
      "${var.instance_name}" = {
        endpoint          = "${module.opensearch.domain_endpoint}:443"
        connection_string = "https://${module.opensearch.domain_endpoint}"
      }
    }
    cloudwatch_logs           = module.opensearch.cloudwatch_logs
    domain_arn                = module.opensearch.domain_arn
    domain_dashboard_endpoint = module.opensearch.domain_dashboard_endpoint
    domain_endpoint           = module.opensearch.domain_endpoint
    domain_id                 = module.opensearch.domain_id
    outbound_connections      = module.opensearch.outbound_connections
    package_associations      = module.opensearch.package_associations
    security_group_arn        = module.opensearch.security_group_arn
    security_group_id         = module.opensearch.security_group_id
    vpc_endpoints             = module.opensearch.vpc_endpoints
  }
}
