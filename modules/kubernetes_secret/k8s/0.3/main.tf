# # Define your terraform resources here

module "facets-secret" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
  name            = lower(var.instance_name)
  namespace       = local.namespace
  advanced_config = {}
  data = merge(
    {
      apiVersion = "v1"
      kind       = "Secret"
      metadata = {
        name        = lower(var.instance_name)
        namespace   = local.namespace
        annotations = lookup(local.metadata, "annotations", {})
        labels      = lookup(local.metadata, "labels", {})
      }
    },
    local.skip_base64_encode ? {
      data = {
        for k, v in lookup(local.spec, "data", {}) : v.key => v.value
      }
    } : {
      data = {
        for k, v in lookup(local.spec, "data", {}) : v.key => base64encode(v.value)
      }
    }
  )
}


# module "facets-secret" {
#   source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
#   name            = lower(var.instance_name)
#   namespace       = local.namespace
#   advanced_config = {}
#   data = {
#     apiVersion = "v1"
#     kind       = "Secret"
#     metadata = {
#       name        = lower(var.instance_name)
#       namespace   = local.namespace
#       annotations = lookup(var.instance.metadata, "annotations", {})
#       labels      = lookup(var.instance.metadata, "labels", {})
#     }
#     data = {
#       for k, v in lookup(local.spec, "data", {}) : v.key => local.skip_base64_encode ? v.value : base64encode(v.value)
#     }
#   }

