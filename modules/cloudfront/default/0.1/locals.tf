locals {
  spec                          = lookup(var.instance, "spec", {})
  advanced                      = lookup(lookup(var.instance, "advanced", {}), "cloudfront", {})
  user_defined_tags             = lookup(local.advanced, "tags", {})
  tags                          = merge(local.user_defined_tags, var.environment.cloud_tags)
  create_origin_access_identity = lookup(local.advanced, "create_origin_access_identity", true)

  raw_aliases = lookup(local.spec, "aliases", "")
  aliases = length(local.raw_aliases) > 0 ? [
    for k, v in local.spec.aliases : v
  ] : []

  raw_viewer_certificate = lookup(local.spec, "viewer_certificate", {})
  viewer_certificate = length(local.raw_viewer_certificate) > 0 ? {
    acm_certificate_arn            = lookup(local.raw_viewer_certificate, "acm_certificate_arn", null)
    cloudfront_default_certificate = lookup(local.raw_viewer_certificate, "cloudfront_default_certificate", null)
    iam_certificate_id             = lookup(local.raw_viewer_certificate, "iam_certificate_id", null)
    minimum_protocol_version       = lookup(local.raw_viewer_certificate, "minimum_protocol_version", "TLSv1")
    ssl_support_method             = lookup(local.raw_viewer_certificate, "ssl_support_method", "sni-only")
    } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

  origins = local.spec.origins

  origin = {
    for k, v in local.origins :
    k => {
      domain_name         = v["domain_name"]
      origin_path         = lookup(v, "origin_path", "")
      connection_attempts = lookup(v, "connection_attempts", null)
      connection_timeout  = lookup(v, "connection_timeout", null)
      custom_origin_config = jsondecode(length(lookup(v, "custom_origin_config", {})) > 0 ? jsonencode({
        http_port                = lookup(lookup(v, "custom_origin_config", {}), "http_port", null)
        https_port               = lookup(lookup(v, "custom_origin_config", {}), "https_port", null)
        origin_protocol_policy   = lookup(lookup(v, "custom_origin_config", {}), "origin_protocol_policy", null)
        origin_ssl_protocols     = lookup(lookup(v, "custom_origin_config", {}), "origin_ssl_protocols", null)
        origin_keepalive_timeout = lookup(lookup(v, "custom_origin_config", {}), "origin_keepalive_timeout", null)
        origin_read_timeout      = lookup(lookup(v, "custom_origin_config", {}), "origin_read_timeout", null)
      }) : jsonencode({}))

      custom_header = [
        for k, v in lookup(v, "custom_header", {}) : {
          name  = k
          value = v
        }
      ]

      origin_shield = length(lookup(v, "origin_shield", {})) > 0 ? {
        enabled              = lookup(lookup(v, "origin_shield", {}), "enabled", null)
        origin_shield_region = lookup(lookup(v, "origin_shield", {}), "origin_shield_region", null)
      } : {}


      s3_origin_config = length(lookup(v, "custom_origin_config", {})) <= 0 ? {
        origin_access_identity = k
      } : {}
    }
  }

  origin_access_identities = local.create_origin_access_identity ? {
    for k, v in local.origins : k => "${k} origin access identity"
  } : {}

  default_cache_behavior = {
    use_forwarded_values       = local.create_cache_policy ? false : lookup(local.spec.default_cache_behavior, "use_forwarded_values", true)
    target_origin_id           = local.spec.default_cache_behavior.target_origin_id
    allowed_methods            = local.spec.default_cache_behavior.allowed_methods
    cached_methods             = local.spec.default_cache_behavior.cached_methods
    viewer_protocol_policy     = local.spec.default_cache_behavior.viewer_protocol_policy
    compress                   = lookup(local.spec.default_cache_behavior, "compress", null)
    field_level_encryption_id  = lookup(local.spec.default_cache_behavior, "field_level_encryption_id", null)
    smooth_streaming           = lookup(local.spec.default_cache_behavior, "smooth_streaming", null)
    trusted_signers            = lookup(local.spec.default_cache_behavior, "trusted_signers", [])
    trusted_key_groups         = lookup(local.spec.default_cache_behavior, "trusted_key_groups", [])
    cache_policy_id            = local.create_cache_policy && local.cache_policy_name != null ? lookup(local.cache_policy_ids, local.cache_policy_name, null) : lookup(local.spec.default_cache_behavior, "cache_policy_id", null)
    origin_request_policy_id   = lookup(local.spec.default_cache_behavior, "origin_request_policy_id", null)
    response_headers_policy_id = lookup(local.spec.default_cache_behavior, "response_headers_policy_id", null)
    realtime_log_config_arn    = lookup(local.spec.default_cache_behavior, "realtime_log_config_arn", null)
    min_ttl                    = lookup(local.spec.default_cache_behavior, "min_ttl", null)
    default_ttl                = lookup(local.spec.default_cache_behavior, "default_ttl", null)
    max_ttl                    = lookup(local.spec.default_cache_behavior, "max_ttl", null)

    forwarded_values = [
      for k, v in lookup(local.spec.default_cache_behavior, "forwarded_values", {}) : {
        query_string              = lookup(v, "query_string", false)
        query_string_cache_keys   = lookup(v, "query_string_cache_keys", [])
        headers                   = lookup(v, "headers", [])
        cookies_forward           = lookup(v, "cookies_forward", "none")
        cookies_whitelisted_names = lookup(v, "cookies_whitelisted_names", null)
      }
    ]

    lambda_function_association = [
      for k, v in lookup(local.spec.default_cache_behavior, "lambda_function_association", {}) : {
        event_type   = v.event_type
        lambda_arn   = v.lambda_arn
        include_body = lookup(v, "include_body", null)
      }
    ]

    function_association = [
      for k, v in lookup(local.spec.default_cache_behavior, "function_association", {}) : {
        event_type   = v.event_type
        function_arn = v.function_arn
      }
    ]
  }

  raw_ordered_cache_behaviors = lookup(local.spec, "ordered_cache_behaviors", lookup(local.advanced, "ordered_cache_behaviors", {}))
  ordered_cache_behaviors = length(local.raw_ordered_cache_behaviors) > 0 ? [
    for k, v in local.raw_ordered_cache_behaviors : {
      use_forwarded_values       = local.create_cache_policy ? false : lookup(local.raw_ordered_cache_behaviors[k], "use_forwarded_values", true)
      target_origin_id           = local.raw_ordered_cache_behaviors[k].target_origin_id
      path_pattern               = lookup(local.raw_ordered_cache_behaviors[k], "path_pattern", null)
      allowed_methods            = local.raw_ordered_cache_behaviors[k].allowed_methods
      cached_methods             = local.raw_ordered_cache_behaviors[k].cached_methods
      viewer_protocol_policy     = local.raw_ordered_cache_behaviors[k].viewer_protocol_policy
      compress                   = lookup(local.raw_ordered_cache_behaviors[k], "compress", null)
      field_level_encryption_id  = lookup(local.raw_ordered_cache_behaviors[k], "field_level_encryption_id", null)
      smooth_streaming           = lookup(local.raw_ordered_cache_behaviors[k], "smooth_streaming", null)
      trusted_signers            = lookup(local.raw_ordered_cache_behaviors[k], "trusted_signers", [])
      trusted_key_groups         = lookup(local.raw_ordered_cache_behaviors[k], "trusted_key_groups", [])
      cache_policy_id            = local.create_cache_policy ? lookup(local.cache_policy_ids, v.cache_policy_name, null) : lookup(local.raw_ordered_cache_behaviors[k], "cache_policy_id", null)
      origin_request_policy_id   = lookup(local.raw_ordered_cache_behaviors[k], "origin_request_policy_id", null)
      response_headers_policy_id = lookup(local.raw_ordered_cache_behaviors[k], "response_headers_policy_id", null)
      realtime_log_config_arn    = lookup(local.raw_ordered_cache_behaviors[k], "realtime_log_config_arn", null)
      min_ttl                    = lookup(local.raw_ordered_cache_behaviors[k], "min_ttl", null)
      default_ttl                = lookup(local.raw_ordered_cache_behaviors[k], "default_ttl", null)
      max_ttl                    = lookup(local.raw_ordered_cache_behaviors[k], "max_ttl", null)

      forwarded_values = [
        for k, v in lookup(local.raw_ordered_cache_behaviors[k], "forwarded_values", {}) : {
          query_string              = lookup(v, "query_string", false)
          query_string_cache_keys   = lookup(v, "query_string_cache_keys", [])
          headers                   = lookup(v, "headers", [])
          cookies_forward           = lookup(v, "cookies_forward", "none")
          cookies_whitelisted_names = lookup(v, "cookies_whitelisted_names", null)
        }
      ]

      lambda_function_association = {
        for k, v in lookup(local.raw_ordered_cache_behaviors[k], "lambda_function_association", {}) : k => {
          event_type   = v.event_type
          lambda_arn   = v.lambda_arn
          include_body = lookup(v, "include_body", null)
        }
      }

      function_association = {
        for k, v in lookup(local.raw_ordered_cache_behaviors[k], "function_association", {}) : k => {
          event_type   = v.event_type
          function_arn = v.function_arn
        }
      }
    }
  ] : []

  raw_custom_error_responses = lookup(local.advanced, "custom_error_responses", {})
  custom_error_responses = [
    for k, v in local.raw_custom_error_responses : {
      error_code            = v.error_code
      response_code         = lookup(v, "response_code", null)
      response_page_path    = lookup(v, "response_page_path", null)
      error_caching_min_ttl = lookup(v, "error_caching_min_ttl", null)
    }
  ]
  cache_policies      = lookup(local.spec, "cache_policies", {})
  create_cache_policy = length(local.cache_policies) > 0 ? true : false
  cache_policy_ids = length(local.cache_policies) > 0 ? {
    for name, policy in aws_cloudfront_cache_policy.cloudfront : name => policy.id
  } : {}
  cache_policy_name = lookup(lookup(local.spec, "default_cache_behavior", {}), "cache_policy_name", null)
}
