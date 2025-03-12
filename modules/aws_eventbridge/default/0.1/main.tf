locals {
  spec           = var.instance.spec
  advanced       = lookup(var.instance, "advanced", {})
  rules          = lookup(local.spec, "rules", {})
  targets        = lookup(lookup(local.spec, "rules", {}), "targets", [])
  event_bus_name = lookup(local.advanced, "event_bus_name", lookup(local.spec, "event_bus_name", "default"))
  flat_target = flatten([
    for k, v in local.rules : [
      for i, target in v.targets : [
        {
          rule_name    = "${module.name.name}-${k}"
          target_arn   = target.arn
          target_input = lookup(target, "input", null)
          target_id    = "${module.name.name}-${k}"
        }
      ]
    ]
  ])
}


resource "aws_cloudwatch_event_rule" "event_rule" {
  for_each            = local.rules
  name                = "${module.name.name}-${each.key}"
  description         = lookup(each.value, "description", null)
  schedule_expression = lookup(each.value, "schedule_expression", null)
  event_pattern       = lookup(each.value, "event_pattern", null) == null ? null : jsonencode(lookup(each.value, "event_pattern", null))
  event_bus_name      = local.event_bus_name
  is_enabled          = lookup(each.value, "is_enabled", true)
  tags                = lookup(each.value, "tags", {})
  role_arn            = aws_iam_role.eventbridge.arn
}

resource "aws_cloudwatch_event_target" "event_target" {
  depends_on = [aws_cloudwatch_event_rule.event_rule]
  for_each   = { for index, target in local.flat_target : target.target_id => target }
  target_id  = each.value.target_id
  rule       = each.value.rule_name
  arn        = each.value.target_arn
  input      = each.value.target_input == null ? null : jsonencode(each.value.target_input)
}
