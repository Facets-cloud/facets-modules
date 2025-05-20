# Define your locals here

locals {
  spec            = lookup(var.instance, "spec", {})
  advanced        = lookup(var.instance, "advanced", {})
  advanced_config = lookup(local.advanced, "aws_api_gateway", {})
  iam_arns        = lookup(local.advanced_config, "iam", {})
  routes          = lookup(local.spec, "routes", {})
  metadata        = lookup(var.instance, "metadata", {})
}
