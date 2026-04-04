module "cloudfront_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = var.instance_name
  resource_type   = "cloudfront"
  limit           = 53
  environment     = var.environment
}


module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.3"

  # Required inputs as per module
  aliases                = local.aliases
  comment                = lookup(local.advanced, "comment", "${module.cloudfront_name.name} CloudFront")
  default_cache_behavior = local.default_cache_behavior
  default_root_object    = lookup(local.advanced, "default_root_object", null)
  is_ipv6_enabled        = lookup(local.advanced, "is_ipv6_enabled", true)
  origin                 = local.origin
  price_class            = lookup(local.advanced, "price_class", "PriceClass_All")
  tags                   = local.tags
  web_acl_id             = lookup(local.spec, "aws_waf_id", lookup(local.advanced, "web_acl_id", null))

  # Optional inputs as per module
  create_distribution                  = lookup(local.advanced, "create_distribution", true)
  create_monitoring_subscription       = lookup(local.advanced, "create_monitoring_subscription", false)
  create_origin_access_identity        = local.create_origin_access_identity
  custom_error_response                = local.custom_error_responses
  enabled                              = lookup(local.advanced, "enabled", true)
  geo_restriction                      = lookup(local.advanced, "geo_restriction", {})
  http_version                         = lookup(local.advanced, "http_version", "http2")
  logging_config                       = lookup(local.advanced, "logging_config", {})
  ordered_cache_behavior               = local.ordered_cache_behaviors
  origin_access_identities             = local.origin_access_identities
  origin_group                         = lookup(local.advanced, "origin_group", {})
  realtime_metrics_subscription_status = lookup(local.advanced, "realtime_metrics_subscription_status", "Enabled")
  retain_on_delete                     = lookup(local.advanced, "retain_on_delete", false)
  viewer_certificate                   = local.viewer_certificate
  wait_for_deployment                  = lookup(local.advanced, "wait_for_deployment", true)
}

resource "aws_cloudfront_cache_policy" "cloudfront" {
  for_each    = local.cache_policies
  name        = each.key
  default_ttl = lookup(each.value, "default_ttl", null)
  min_ttl     = lookup(each.value, "min_ttl", null)
  max_ttl     = lookup(each.value, "max_ttl", null)
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = lookup(lookup(lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", {}), "cookies_config", {}), "cookie_behavior", "none")
      cookies {
        items = lookup(lookup(lookup(lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", {}), "cookies_config", {}), "cookies", {}), "items", [])
      }
    }
    headers_config {
      header_behavior = lookup(lookup(lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", {}), "headers_config", {}), "header_behavior", "none")
      headers {
        items = lookup(lookup(lookup(lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", {}), "headers_config", {}), "headers", {}), "items", [])
      }
    }
    query_strings_config {
      query_string_behavior = lookup(lookup(lookup(each.value, "local.parameters_in_cache_key_and_forwarded_to_origin", {}), "query_strings_config", {}), "query_string_behavior", "none")
      query_strings {
        items = lookup(lookup(lookup(lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", {}), "query_strings_config", {}), "query_strings", {}), "items", [])
      }
    }
    enable_accept_encoding_brotli = lookup(lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", {}), "enable_accept_encoding_brotli", false)
    enable_accept_encoding_gzip   = lookup(lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", {}), "enable_accept_encoding_gzip", false)
  }
}
