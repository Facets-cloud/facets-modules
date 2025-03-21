locals {
  advanced          = lookup(var.instance, "advanced", {})
  spec              = lookup(var.instance, "spec", {})
  advanced_default  = lookup(local.advanced, "default", {})
  aws_wafv2_web_acl = lookup(local.advanced_default, "aws_wafv2_web_acl", {})
  default_action    = lookup(local.spec, "default_action", {})
  rules = merge({ for key, value in lookup(local.spec, "rule_groups", {}) :
    key => {
      priority = value.priority,
      statement = value.arn != null ? {
        rule_group_reference_statement = {
          arn = value.arn
        }
      } : {}
    }
  }, lookup(local.spec, "rules", {}))
  nested_statements = ["and_statement", "or_statement", "not_statement", "rate_based_statement.scope_down_statement"]
}
