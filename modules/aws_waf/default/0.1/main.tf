module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 64
  resource_name   = var.instance_name
  resource_type   = "waf"
  globally_unique = false
  is_k8s          = false
}

resource "aws_wafv2_web_acl" "this" {
  # commenting attributes that are in compatible with aws provider version 3.74.0
  #  dynamic "association_config" {
  #    for_each = lookup(local.aws_wafv2_web_acl, "association_config", null) != null ? {association_config = lookup(local.aws_wafv2_web_acl, "association_config", {})} : {}
  #    content {
  #      dynamic "request_body" {
  #        for_each = lookup(association_config.value, "request_body", null) != null ? {request_body = lookup(association_config.value, "request_body", {})} : {}
  #        content {
  #          dynamic "cloudfront" {
  #            for_each = lookup(request_body.value, "cloudfront", null) != null ? {cloudfront = lookup(request_body.value, "cloudfront", {})} : {}
  #            content {
  #              default_size_inspection_limit = lookup(cloudfront.value, "default_size_inspection_limit", null)
  #            }
  #          }
  #        }
  #      }
  #
  #    }
  #  }
  #  dynamic "captcha_config" {
  #    for_each = lookup(local.aws_wafv2_web_acl, "captcha_config", null) != null ? {captcha_config = lookup(local.aws_wafv2_web_acl, "captcha_config", {})} : {}
  #    content {
  #      dynamic "immunity_time_property" {
  #        for_each = lookup(captcha_config.value, "immunity_time_property", null) != null ? lookup(captcha_config.value, "immunity_time_property", {}) : {}
  #        content {
  #          immunity_time = lookup(immunity_time_property.value, "immunity_time", null)
  #        }
  #      }
  #    }
  #  }
  #  dynamic "challenge_config" {
  #    for_each = lookup(local.aws_wafv2_web_acl, "challenge_config", null) != null ? {challenge_config = lookup(local.aws_wafv2_web_acl, "challenge_config", {})} : {}
  #    content {
  #      dynamic "immunity_time_property" {
  #        for_each = lookup(challenge_config.value, "immunity_time_property", null) != null ? lookup(challenge_config.value, "immunity_time_property", {}) : {}
  #        content {
  #          immunity_time = lookup(immunity_time_property.value, "immunity_time", null)
  #        }
  #      }
  #    }
  #  }
  dynamic "custom_response_body" {
    for_each = lookup(local.aws_wafv2_web_acl, "custom_response_body", {})
    content {
      key          = custom_response_body.key
      content      = lookup(custom_response_body.value, "content", null)
      content_type = lookup(custom_response_body.value, "content_type", null)
    }
  }
  default_action {
    dynamic "allow" {
      for_each = lookup(local.default_action, "allow", null) != null ? { allow = lookup(local.default_action, "allow", {}) } : {}
      content {
        dynamic "custom_request_handling" {
          for_each = lookup(allow.value, "custom_request_handling", null) != null ? { custom_request_handling = lookup(allow.value, "custom_request_handling", {}) } : {}
          content {
            dynamic "insert_header" {
              for_each = lookup(custom_request_handling.value, "insert_header", {})
              content {
                name  = lookup(insert_header.value, "name", null)
                value = lookup(insert_header.value, "value", null)
              }
            }
          }
        }
      }
    }
    dynamic "block" {
      for_each = lookup(local.default_action, "block", null) != null ? { block = lookup(local.default_action, "block", {}) } : {}
      content {
        dynamic "custom_response" {
          for_each = lookup(block.value, "custom_response", null) != null ? { custom_response = lookup(block.value, "custom_response", {}) } : {}
          content {
            custom_response_body_key = lookup(custom_response.value, "custom_response_body_key", null)
            response_code            = lookup(custom_response.value, "response_code", null)
            dynamic "response_header" {
              for_each = lookup(custom_response.value, "response_header", {})
              content {
                name  = lookup(response_header.value, "name", null)
                value = lookup(response_header.value, "value", null)
              }
            }
          }
        }
      }
    }
  }
  description = lookup(local.aws_wafv2_web_acl, "description", "Facets managed WAF resource ${var.instance_name}")
  name        = module.name.name
  dynamic "rule" {
    for_each = local.rules
    content {
      dynamic "action" {
        for_each = lookup(rule.value, "action", null) != null ? { action = lookup(rule.value, "action", {}) } : {}
        content {
          dynamic "allow" {
            for_each = lookup(action.value, "allow", null) != null ? { allow = lookup(action.value, "allow", {}) } : {}
            content {
              dynamic "custom_request_handling" {
                for_each = lookup(allow.value, "custom_request_handling", null) != null ? { custom_request_handling = lookup(allow.value, "custom_request_handling", {}) } : {}
                content {
                  dynamic "insert_header" {
                    for_each = lookup(custom_request_handling.value, "insert_header", null) != null ? { insert_header = lookup(custom_request_handling.value, "insert_header", {}) } : {}
                    content {
                      name  = lookup(insert_header.value, "name", null)
                      value = lookup(insert_header.value, "value", null)
                    }
                  }
                }
              }
            }
          }
          dynamic "block" {
            for_each = lookup(action.value, "block", null) != null ? { block = lookup(action.value, "block", {}) } : {}
            content {
              dynamic "custom_response" {
                for_each = lookup(block.value, "custom_response", null) != null ? { custom_response = lookup(block.value, "custom_response", {}) } : {}
                content {
                  custom_response_body_key = lookup(custom_response.value, "custom_response_body_key", null)
                  response_code            = lookup(custom_response.value, "response_code", null)
                  dynamic "response_header" {
                    for_each = lookup(custom_response.value, "response_header", null) != null ? { response_header = lookup(custom_response.value, "response_header", {}) } : {}
                    content {
                      name  = lookup(response_header.value, "name", null)
                      value = lookup(response_header.value, "value", null)
                    }
                  }
                }
              }
            }
          }
          dynamic "count" {
            for_each = lookup(action.value, "count", null) != null ? { count = lookup(action.value, "count", {}) } : {}
            content {
              dynamic "custom_request_handling" {
                for_each = lookup(count.value, "custom_request_handling", null) != null ? { custom_request_handling = lookup(count.value, "custom_request_handling", {}) } : {}
                content {
                  dynamic "insert_header" {
                    for_each = lookup(custom_request_handling.value, "insert_header", null) != null ? { insert_header = lookup(custom_request_handling.value, "insert_header", {}) } : {}
                    content {
                      name  = lookup(insert_header.value, "name", null)
                      value = lookup(insert_header.value, "value", null)
                    }
                  }
                }
              }
            }
          }
        }
      }
      name = rule.key
      dynamic "override_action" {
        for_each = lookup(rule.value, "override_action", null) != null ? { override_action = lookup(rule.value, "override_action", {}) } : contains(keys(lookup(rule.value, "statement", {})), "rule_group_reference_statement") ? { override_action = { none = {} } } : {}
        content {
          dynamic "count" {
            for_each = contains(keys(override_action.value), "count") ? { count = true } : {}
            content {}
          }
          dynamic "none" {
            for_each = contains(keys(override_action.value), "none") ? { none = true } : {}
            content {}
          }
        }
      }
      priority = lookup(rule.value, "priority", null)
      dynamic "rule_label" {
        for_each = lookup(rule.value, "rule_label", {})
        content {
          name = lookup(rule_label.value, "name", null)
        }
      }
      dynamic "statement" {
        for_each = lookup(rule.value, "statement", null) != null ? { statement = lookup(rule.value, "statement", {}) } : {}
        content {
          dynamic "and_statement" {
            for_each = lookup(statement.value, "and_statement", null) != null ? { and_statement = lookup(statement.value, "and_statement", {}) } : {}
            content {
              dynamic "statement" {
                for_each = and_statement.value
                content {
                  #statements
                }
              }
            }
          }
          dynamic "byte_match_statement" {
            for_each = lookup(statement.value, "byte_match_statement", null) != null ? { byte_match_statement = lookup(statement.value, "byte_match_statement", {}) } : {}
            content {
              dynamic "field_to_match" {
                for_each = lookup(byte_match_statement.value, "field_to_match", null) != null ? { field_to_match = lookup(byte_match_statement.value, "field_to_match", {}) } : {}
                content {
                  dynamic "all_query_arguments" {
                    for_each = contains(field_to_match.value, "all_query_arguments") ? { all_query_arguments = true } : null
                    content {}
                  }
                  dynamic "body" {
                    for_each = contains(field_to_match.value, "body") ? { body = true } : null
                    content {}
                  }
                  dynamic "method" {
                    for_each = contains(field_to_match.value, "method") ? { method = true } : null
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = contains(field_to_match.value, "query_string") ? { query_string = true } : null
                    content {}
                  }
                  dynamic "single_header" {
                    for_each = lookup(field_to_match.value, "single_header", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_header.value, "name", null)
                    }
                  }
                  dynamic "single_query_argument" {
                    for_each = lookup(field_to_match.value, "single_query_argument", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_query_argument.value, "name", null)
                    }
                  }
                  dynamic "uri_path" {
                    for_each = contains(field_to_match.value, "uri_path") ? { uri_path = true } : null
                    content {}
                  }
                }
              }
              positional_constraint = lookup(byte_match_statement.value, "positional_constraint", null)
              search_string         = lookup(byte_match_statement.value, "search_string", null)
              dynamic "text_transformation" {
                for_each = lookup(byte_match_statement.value, "text_transformation", null) != null ? { text_transformation = lookup(byte_match_statement.value, "text_transformation", {}) } : {}
                content {
                  priority = lookup(text_transformation.value, "priority", null)
                  type     = lookup(text_transformation.value, "type", null)
                }
              }
            }
          }
          dynamic "geo_match_statement" {
            for_each = lookup(statement.value, "geo_match_statement", null) != null ? { geo_match_statement = lookup(statement.value, "geo_match_statement", {}) } : {}
            content {
              country_codes = lookup(geo_match_statement.value, "country_codes", null)
              dynamic "forwarded_ip_config" {
                for_each = lookup(geo_match_statement.value, "forwarded_ip_config", null) != null ? { geo_match_statement = lookup(geo_match_statement.value, "forwarded_ip_config", {}) } : {}
                content {
                  fallback_behavior = lookup(forwarded_ip_config.value, "fallback_behaviour", null)
                  header_name       = lookup(forwarded_ip_config.value, "header_name", null)
                }
              }
            }
          }
          dynamic "ip_set_reference_statement" {
            for_each = lookup(statement.value, "ip_set_reference_statement", null) != null ? { ip_set_reference_statement = lookup(statement.value, "ip_set_reference_statement", {}) } : {}
            content {
              arn = lookup(ip_set_reference_statement.value, "arn", null)
              dynamic "ip_set_forwarded_ip_config" {
                for_each = lookup(ip_set_reference_statement.value, "ip_set_forward_ip_config", null) != null ? { ip_set_forward_ip_config = lookup(ip_set_reference_statement.value, "ip_set_forward_ip_config", {}) } : {}
                content {
                  fallback_behavior = lookup(ip_set_forwarded_ip_config.value, "fallback_behavior", null)
                  header_name       = lookup(ip_set_forwarded_ip_config.value, "header_name", null)
                  position          = lookup(ip_set_forwarded_ip_config.value, "position", null)
                }
              }
            }
          }
          dynamic "label_match_statement" {
            for_each = lookup(statement.value, "label_match_statement", null) != null ? { label_match_statement = lookup(statement.value, "label_match_statement", {}) } : {}
            content {
              scope = lookup(label_match_statement.value, "scope", null)
              key   = lookup(label_match_statement.value, "key", null)
            }
          }
          dynamic "managed_rule_group_statement" {
            for_each = lookup(statement.value, "managed_rule_group_statement", null) != null ? { managed_rule_group_statement = lookup(statement.value, "managed_rule_group_statement", {}) } : {}
            content {
              name        = lookup(managed_rule_group_statement.value, "name", null)
              vendor_name = lookup(managed_rule_group_statement.value, "vendor_name", null)
              dynamic "excluded_rule" {
                for_each = lookup(managed_rule_group_statement.value, "excluded_rule", null)
                content {
                  name = lookup(excluded_rule.value, "name", null)
                }
              }
            }
          }
          dynamic "not_statement" {
            for_each = lookup(statement.value, "not_statement", null) != null ? { not_statement = lookup(statement.value, "not_statement", {}) } : {}
            content {
              statement {
                # statements
              }
            }
          }
          dynamic "or_statement" {
            for_each = lookup(statement.value, "or_statement", null) != null ? { or_statement = lookup(statement.value, "or_statement", {}) } : {}
            content {
              statement {
                #statements
              }
            }
          }
          dynamic "rate_based_statement" {
            for_each = lookup(statement.value, "rate_based_statement", null) != null ? { rate_based_statement = lookup(statement.value, "rate_based_statement", {}) } : {}
            content {
              aggregate_key_type = lookup(rate_based_statement.value, "aggregate_key_type", null)
              dynamic "forwarded_ip_config" {
                for_each = lookup(rate_based_statement.value, "forwarded_ip_config", null) != null ? { forwarded_ip_config = lookup(rate_based_statement.value, "forwarded_ip_config", {}) } : {}
                content {
                  fallback_behavior = lookup(forwarded_ip_config.value, "fallback_behavior", null)
                  header_name       = lookup(forwarded_ip_config.value, "header_name", null)
                }
              }
              limit = lookup(rate_based_statement.value, "limit", null)
              dynamic "scope_down_statement" {
                for_each = lookup(rate_based_statement.value, "scope_down_statement", null) != null ? { scope_down_statement = lookup(rate_based_statement.value, "scope_down_statement", {}) } : {}
                content {
                  # statement block
                }
              }
            }
          }
          dynamic "regex_pattern_set_reference_statement" {
            for_each = lookup(statement.value, "regex_pattern_set_reference_statement", null) != null ? { regex_pattern_set_reference_statement = lookup(statement.value, "regex_pattern_set_reference_statement", {}) } : {}
            content {
              arn = lookup(regex_pattern_set_reference_statement.value, "arn", null)
              dynamic "field_to_match" {
                for_each = lookup(regex_pattern_set_reference_statement.value, "field_to_match", null) != null ? { field_to_match = lookup(regex_pattern_set_reference_statement.value, "field_to_match", {}) } : {}
                content {
                  dynamic "all_query_arguments" {
                    for_each = contains(field_to_match.value, "all_query_arguments") ? { all_query_arguments = true } : null
                    content {}
                  }
                  dynamic "body" {
                    for_each = contains(field_to_match.value, "body") ? { body = true } : null
                    content {}
                  }
                  dynamic "method" {
                    for_each = contains(field_to_match.value, "method") ? { method = true } : null
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = contains(field_to_match.value, "query_string") ? { query_string = true } : null
                    content {}
                  }
                  dynamic "single_header" {
                    for_each = lookup(field_to_match.value, "single_header", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_header.value, "name", null)
                    }
                  }
                  dynamic "single_query_argument" {
                    for_each = lookup(field_to_match.value, "single_query_argument", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_query_argument.value, "name", null)
                    }
                  }
                  dynamic "uri_path" {
                    for_each = contains(field_to_match.value, "uri_path") ? { uri_path = true } : null
                    content {}
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = lookup(regex_pattern_set_reference_statement.value, "text_transformation", null) != null ? { text_transformation = lookup(regex_pattern_set_reference_statement.value, "text_transformation", {}) } : {}
                content {
                  priority = lookup(text_transformation.value, "priority", null)
                  type     = lookup(text_transformation.value, "type", null)
                }
              }
            }
          }
          dynamic "rule_group_reference_statement" {
            for_each = try({ rule_group_reference_statement = statement.value.rule_group_reference_statement }, {})
            content {
              arn = lookup(rule_group_reference_statement.value, "arn", null)
              dynamic "excluded_rule" {
                for_each = lookup(rule_group_reference_statement.value, "excluded_rule", {})
                content {
                  name = lookup(excluded_rule.value, "name", null)
                }
              }
            }
          }
          dynamic "size_constraint_statement" {
            for_each = lookup(statement.value, "size_constraint_statement", null) != null ? { size_constraint_statement = lookup(statement.value, "size_constraint_statement", {}) } : {}
            content {
              comparison_operator = lookup(size_constraint_statement.value, "comparison_operator", null)
              dynamic "field_to_match" {
                for_each = lookup(size_constraint_statement.value, "field_to_match", null) != null ? { field_to_match = lookup(size_constraint_statement.value, "field_to_match", {}) } : {}
                content {
                  dynamic "all_query_arguments" {
                    for_each = contains(field_to_match.value, "all_query_arguments") ? { all_query_arguments = true } : null
                    content {}
                  }
                  dynamic "body" {
                    for_each = contains(field_to_match.value, "body") ? { body = true } : null
                    content {}
                  }
                  dynamic "method" {
                    for_each = contains(field_to_match.value, "method") ? { method = true } : null
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = contains(field_to_match.value, "query_string") ? { query_string = true } : null
                    content {}
                  }
                  dynamic "single_header" {
                    for_each = lookup(field_to_match.value, "single_header", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_header.value, "name", null)
                    }
                  }
                  dynamic "single_query_argument" {
                    for_each = lookup(field_to_match.value, "single_query_argument", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_query_argument.value, "name", null)
                    }
                  }
                  dynamic "uri_path" {
                    for_each = contains(field_to_match.value, "uri_path") ? { uri_path = true } : null
                    content {}
                  }
                }
              }
              size = lookup(size_constraint_statement.value, "size", null)
              dynamic "text_transformation" {
                for_each = lookup(size_constraint_statement.value, "text_transformation", null) != null ? { text_transformation = lookup(size_constraint_statement.value, "text_transformation", {}) } : {}
                content {
                  priority = lookup(text_transformation.value, "priority", null)
                  type     = lookup(text_transformation.value, "type", null)
                }
              }
            }
          }
          dynamic "sqli_match_statement" {
            for_each = lookup(statement.value, "sqli_match_statement", null) != null ? { sqli_match_statement = lookup(statement.value, "sqli_match_statement", {}) } : {}
            content {
              dynamic "field_to_match" {
                for_each = lookup(sqli_match_statement.value, "field_to_match", null) != null ? { field_to_match = lookup(sqli_match_statement.value, "field_to_match", {}) } : {}
                content {
                  dynamic "all_query_arguments" {
                    for_each = contains(field_to_match.value, "all_query_arguments") ? { all_query_arguments = true } : null
                    content {}
                  }
                  dynamic "body" {
                    for_each = contains(field_to_match.value, "body") ? { body = true } : null
                    content {}
                  }
                  dynamic "method" {
                    for_each = contains(field_to_match.value, "method") ? { method = true } : null
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = contains(field_to_match.value, "query_string") ? { query_string = true } : null
                    content {}
                  }
                  dynamic "single_header" {
                    for_each = lookup(field_to_match.value, "single_header", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_header.value, "name", null)
                    }
                  }
                  dynamic "single_query_argument" {
                    for_each = lookup(field_to_match.value, "single_query_argument", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_query_argument.value, "name", null)
                    }
                  }
                  dynamic "uri_path" {
                    for_each = contains(field_to_match.value, "uri_path") ? { uri_path = true } : null
                    content {}
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = lookup(sqli_match_statement.value, "text_transformation", null) != null ? { text_transformation = lookup(sqli_match_statement.value, "text_transformation", {}) } : {}
                content {
                  priority = lookup(text_transformation.value, "priority", null)
                  type     = lookup(text_transformation.value, "type", null)
                }
              }
            }
          }
          dynamic "xss_match_statement" {
            for_each = lookup(statement.value, "xss_match_statement", null) != null ? { xss_match_statement = lookup(statement.value, "xss_match_statement", {}) } : {}
            content {
              dynamic "field_to_match" {
                for_each = lookup(xss_match_statement.value, "field_to_match", null) != null ? { field_to_match = lookup(xss_match_statement.value, "field_to_match", {}) } : {}
                content {
                  dynamic "all_query_arguments" {
                    for_each = contains(field_to_match.value, "all_query_arguments") ? { all_query_arguments = true } : null
                    content {}
                  }
                  dynamic "body" {
                    for_each = contains(field_to_match.value, "body") ? { body = true } : null
                    content {}
                  }
                  dynamic "method" {
                    for_each = contains(field_to_match.value, "method") ? { method = true } : null
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = contains(field_to_match.value, "query_string") ? { query_string = true } : null
                    content {}
                  }
                  dynamic "single_header" {
                    for_each = lookup(field_to_match.value, "single_header", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_header.value, "name", null)
                    }
                  }
                  dynamic "single_query_argument" {
                    for_each = lookup(field_to_match.value, "single_query_argument", null) != null ? { single_header = lookup(field_to_match.value, "single_header", {}) } : {}
                    content {
                      name = lookup(single_query_argument.value, "name", null)
                    }
                  }
                  dynamic "uri_path" {
                    for_each = contains(field_to_match.value, "uri_path") ? { uri_path = true } : null
                    content {}
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = lookup(xss_match_statement.value, "text_transformation", null) != null ? { text_transformation = lookup(xss_match_statement.value, "text_transformation", {}) } : {}
                content {
                  priority = lookup(text_transformation.value, "priority", null)
                  type     = lookup(text_transformation.value, "type", null)
                }
              }
            }
          }
        }
      }
      dynamic "visibility_config" {
        for_each = lookup(rule.value, "visibility_config", null) != null ? { visibility_config = lookup(rule.value, "visibility_config", {}) } : { visibility_config = { cloudwatch_metrics_enabled = false, metric_name = "All", sampled_requests_enabled = false } }
        content {
          cloudwatch_metrics_enabled = lookup(visibility_config.value, "cloudwatch_metrics_enabled", null)
          metric_name                = lookup(visibility_config.value, "metric_name", null)
          sampled_requests_enabled   = lookup(visibility_config.value, "sampled_requests_enabled", null)
        }
      }
    }
  }
  scope = local.spec.scope
  tags  = merge(lookup(local.aws_wafv2_web_acl, "tags", {}), var.environment.cloud_tags)
  dynamic "visibility_config" {
    for_each = lookup(local.aws_wafv2_web_acl, "visibility_config", null) != null ? { visibility_config = lookup(local.aws_wafv2_web_acl, "visibility_config", {}) } : { visibility_config = { cloudwatch_metrics_enabled = false, metric_name = "All", sampled_requests_enabled = false } }
    content {
      cloudwatch_metrics_enabled = lookup(visibility_config.value, "cloudwatch_metrics_enabled", null)
      metric_name                = lookup(visibility_config.value, "metric_name", null)
      sampled_requests_enabled   = lookup(visibility_config.value, "sampled_requests_enabled", null)
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  for_each     = local.spec.scope == "REGIONAL" ? lookup(local.spec, "resource_arns", {}) : {}
  resource_arn = each.value.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
