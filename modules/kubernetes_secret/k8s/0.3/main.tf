# # Define your terraform resources here

module "facets-secret" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = lower(var.instance_name)
  namespace       = local.namespace
  advanced_config = {}
  data = {
      apiVersion = "v1"
      kind       = "Secret"
      metadata = {
        name        = lower(var.instance_name)
        namespace   = local.namespace
        annotations = lookup(local.metadata, "annotations", {})
        labels      = lookup(local.metadata, "labels", {})
      }
      data = {
        for k, v in lookup(local.spec, "data", {}) : v.key => local.skip_base64_encode ? v.value : base64encode(v.value)
      }
    }
}




