locals {
  advanced_config      = lookup(lookup(var.instance, "advanced", {}), "k8s_resource", {})
  metadata             = lookup(var.instance, "metadata", {})
  data                 = lookup(var.instance.spec, "resource", {})
  spec                 = lookup(var.instance, "spec", {})
  namespace_meta       = lookup(lookup(var.instance, "metadata", {}), "namespace", null) # in the .metadata block
  namespace_spec       = lookup(lookup(local.data, "metadata", {}), "namespace", null)   # in the .spec.resource.metadata block
  namespace            = coalesce(local.namespace_spec, local.namespace_meta, var.environment.namespace)
  resource_name        = lookup(local.metadata, "name", var.instance_name)
  name                 = length(local.resource_name) >= 63 ? substr(md5("${local.resource_name}"), 0, 20) : "${local.resource_name}"
  additional_resources = { for k, v in lookup(local.spec, "additional_resources", {}) : k => v.configuration }
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 63
  resource_name   = var.instance_name
  resource_type   = "k8s-resource"
  is_k8s          = true
  globally_unique = false
}
module "k8s-any-resource" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = local.name
  release_name    = module.name.name
  namespace       = local.namespace
  data            = local.data
  advanced_config = local.advanced_config
}


module "add-k8s-any-resource" {
  count           = length(local.additional_resources) > 0 ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
  name            = length("${local.name}-ak8s") >= 40 ? substr(md5("${local.name}-ak8s"), 0, 20) : "${local.name}-ak8s"
  release_name    = length("${module.name.name}-ak8s") >= 40 ? substr(md5("${module.name.name}-ak8s"), 0, 20) : "${module.name.name}-ak8s"
  namespace       = local.namespace
  resources_data  = local.additional_resources
  advanced_config = local.advanced_config
}

