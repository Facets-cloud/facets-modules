locals {
  spec     = lookup(var.instance, "spec", {})
  advanced = lookup(var.instance, "advanced", {})
  iam_role = lookup(local.advanced, "iam_role", {})
  role_id  = lookup(local.spec, "role_id", null)
}

module "gcp_custome_role_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 63
  resource_name   = var.instance_name
  resource_type   = "gcp_iam_role"
  globally_unique = false
  is_k8s          = false
}
module "gcp_custom_role" {
  source = "./terraform-google-iam-master/modules/custom_role_iam"

  target_level         = "project"     # project or organization level
  role_id              = local.role_id # has regex; example: testRole
  target_id            = lookup(local.spec, "target_id", var.inputs.network_details.attributes.legacy_outputs.gcp_cloud.project_id)
  description          = lookup(local.iam_role, "description", "Custom role ${module.gcp_custome_role_name.name} created with role id ${local.role_id}")
  permissions          = lookup(local.spec, "permissions", [])
  excluded_permissions = lookup(local.spec, "excluded_permissions", [])
  members              = lookup(local.spec, "members", [])
  base_roles           = lookup(local.spec, "base_roles", [])
  stage                = lookup(local.spec, "stage", "GA")
  title                = lookup(local.iam_role, "title", "${module.gcp_custome_role_name.name}-${local.role_id}")
}
