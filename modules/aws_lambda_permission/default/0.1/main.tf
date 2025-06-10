resource "aws_lambda_permission" "version_triggers" {
  for_each           = { for k, v in lookup(local.spec, "allowed_triggers", {}) : k => v }
  function_name      = lookup(local.spec, "lambda_name", lookup(lookup(lookup(var.inputs, "lambda_details", {}), "attributes", {}), "function_name", ""))
  qualifier          = lookup(local.spec, "lambda_version", null)
  statement_id       = lookup(each.value, "statement_id", each.key)
  action             = lookup(each.value, "action", "lambda:InvokeFunction")
  principal          = lookup(each.value, "principal", format("%s.amazonaws.com", lookup(each.value, "service", "")))
  source_arn         = lookup(each.value, "source_arn", null)
  source_account     = lookup(each.value, "source_account", null)
  event_source_token = lookup(each.value, "event_source_token", null)
}
