locals {
  advanced_iam_policy = lookup(lookup(lookup(var.instance, "advanced", {}), "iam_policy", {}), "aws_iam_policy", {})
  user_defined_tags   = lookup(var.cc_metadata, "tags", {})
  spec                = var.instance.spec
  policy              = var.instance.spec.policy
  tags                = merge(var.environment.cloud_tags, local.user_defined_tags)
}

module "iam-policy-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = var.instance_name
  resource_type   = "iam_policy"
  limit           = 60
  environment     = var.environment
}

resource "aws_iam_policy" "iam_policy" {
  name        = module.iam-policy-name.name
  path        = lookup(local.advanced_iam_policy, "path", "/")
  description = lookup(local.advanced_iam_policy, "description", null)
  tags        = local.tags
  policy      = jsonencode(local.policy)

  lifecycle {
    ignore_changes = [name]
  }
}
