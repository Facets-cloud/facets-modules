# Define your terraform resources here

module "apigateway-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = lower(var.instance_name)
  resource_type   = "aws_apigateway"
  limit           = 50
  environment     = var.environment
}


module "api_gateway" {
  source                                   = "terraform-aws-modules/apigateway-v2/aws"
  version                                  = "1.8.0"
  name                                     = module.apigateway-name.name
  description                              = lookup(local.metadata, "description", "default api gateway provisioned by facets")
  protocol_type                            = lookup(local.spec, "protocol", "HTTP")
  cors_configuration                       = lookup(local.advanced_config, "cors", {})
  domain_name                              = lookup(local.advanced_config, "domain_name", null)
  domain_name_certificate_arn              = lookup(local.advanced_config, "domain_name_certificate_arn", null)
  default_stage_access_log_destination_arn = lookup(local.advanced_config, "default_stage_access_log_destination_arn", null)
  default_stage_access_log_format          = lookup(local.advanced_config, "default_stage_access_log_format", null)
  authorizers                              = lookup(local.advanced_config, "authorizers", {})
  default_route_settings                   = lookup(local.advanced_config, "default_route_settings", {})
  mutual_tls_authentication                = lookup(local.advanced_config, "mutual_tls_authentication", {})
  body                                     = lookup(local.advanced_config, "body", null)
  tags                                     = merge(var.environment.cloud_tags, lookup(local.advanced_config, "tags", {}))
  api_version                              = lookup(local.advanced_config, "api_version", null)
  route_selection_expression               = lookup(local.advanced_config, "route_selection_expression", null)
  route_key                                = lookup(local.advanced_config, "route_key", null)
  api_key_selection_expression             = lookup(local.advanced_config, "api_key_selection_expression", null)
  disable_execute_api_endpoint             = lookup(local.advanced_config, "disable_execute_api_endpoint", false)
  create_default_stage                     = length(lookup(local.spec, "routes", {})) > 0 ? true : lookup(local.advanced_config, "create_default_stage", false)
  create_default_stage_api_mapping         = length(lookup(local.spec, "routes", {})) > 0 ? true : lookup(local.advanced_config, "create_default_stage_api_mapping", false)
  create_api_domain_name                   = lookup(local.advanced_config, "domain_name", null) == null ? lookup(local.advanced_config, "create_api_domain_name", false) : true
  create_routes_and_integrations           = length(lookup(local.spec, "routes", {})) > 0 ? true : lookup(local.advanced_config, "create_routes_and_integrations", false)
  create_vpc_link                          = lookup(local.advanced_config, "create_vpc_link", true)
  vpc_links = merge({
    "${module.apigateway-name.name}-vpc" = {
      security_group_ids = [var.inputs.network_details.attributes.legacy_outputs.vpc_details.default_security_group_id]
      subnet_ids         = var.inputs.network_details.attributes.legacy_outputs.vpc_details.public_subnets
    }
    },
  lookup(local.advanced_config, "vpc_links", {}))
  integrations = local.routes
}
