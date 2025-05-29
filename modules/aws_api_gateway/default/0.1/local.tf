


# locals {
#   spec            = lookup(var.instance, "spec", {})
#   advanced        = lookup(var.instance, "advanced", {})
#   advanced_config = lookup(local.advanced, "aws_api_gateway", {})
#   metadata        = lookup(var.instance, "metadata", {})

#   # Transform routes for API Gateway with proper format
#   routes = {
#     for route_key, route_config in lookup(local.spec, "routes", {}) :
#     route_key => {
#       integration_type     = route_config.integration_type
#       integration_uri      = route_config.integration_uri
#       timeout_milliseconds = route_config.timeout_milliseconds
#       route_key            = "${route_config.method} ${route_config.path}"
#       integration_method   = route_config.method
#     }
#   }
# }


# locals {
#   spec            = lookup(var.instance, "spec", {})
#   advanced        = lookup(var.instance, "advanced", {})
#   advanced_config = lookup(local.advanced, "aws_api_gateway", {})
#   metadata        = lookup(var.instance, "metadata", {})

#   # Transform routes for API Gateway - use proper route key format
#   routes = {
#     for route_key, route_config in lookup(local.spec, "routes", {}) :
#     "${route_config.method} ${route_config.path}" => {
#       integration_type     = route_config.integration_type
#       integration_uri      = route_config.integration_uri
#       timeout_milliseconds = route_config.timeout_milliseconds
#     }
#   }
# }

# Define your locals here

locals {
  spec            = lookup(var.instance, "spec", {})
  advanced        = lookup(var.instance, "advanced", {})
  advanced_config = lookup(local.advanced, "aws_api_gateway", {})
  metadata        = lookup(var.instance, "metadata", {})

  # Transform routes for API Gateway - HTTP protocol doesn't need route_response_selection_expression
  routes = {
    for route_key, route_config in lookup(local.spec, "routes", {}) :
    "${route_config.method} ${route_config.path}" => {
      integration_type     = route_config.integration_type
      integration_uri      = route_config.integration_uri
      timeout_milliseconds = route_config.timeout_milliseconds
      integration_method   = route_config.method
      route_key            = "${route_config.method} ${route_config.path}"
    }
  }
}
