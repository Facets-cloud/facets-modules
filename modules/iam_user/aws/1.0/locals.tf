locals {
  spec                  = var.instance.spec
  user_name             = lookup(local.spec, "name_override", "")
  name_override_present = local.user_name != ""
  path                  = lookup(local.spec, "path", "/")
  user_tags_map         = lookup(local.spec, "tags", {})
  policy_arn_map        = lookup(local.spec, "policy_arns", {})
  policy_arns           = toset([for arn in local.policy_arn_map : arn.policy_arn if arn.policy_arn != null])
  custom_policies_map   = lookup(local.spec, "custom_policies", {})
  custom_policies = {
    for key, policy_object in local.custom_policies_map :
    key => {
      name   = policy_object.name
      policy = policy_object.policy
    }
    if policy_object.name != null && policy_object.policy != null
  }
  user_tags = { for k, v in local.user_tags_map : v.tag_name => v.tag_value if v != null && v.tag_name != null && v.tag_value != null }
  tags = merge(
    var.environment.cloud_tags,
    {
      "resourceType" : "iam_user",
      "resourceName" : var.instance_name,
    },
    local.user_tags
  )
}
