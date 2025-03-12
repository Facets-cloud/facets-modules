locals {
  output_attributes = {
    rule_id   = { for k, v in aws_cloudwatch_event_rule.event_rule : k => v.id }
    rule_arn  = { for k, v in aws_cloudwatch_event_rule.event_rule : k => v.arn }
    rule_name = { for k, v in aws_cloudwatch_event_rule.event_rule : k => v.name }
  }
  output_interfaces = {}
}
