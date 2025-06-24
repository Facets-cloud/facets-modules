
locals {
  metadata        = lookup(var.instance, "metadata", {})
  spec            = lookup(var.instance, "spec", {})
  advanced_config = lookup(lookup(var.instance, "advanced", {}), "k8s", {})
  namespace       = lookup(local.metadata, "namespace", null) == null ? var.environment.namespace : var.instance.metadata.namespace
}

module "facets-configmap" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = lower(var.instance_name)
  namespace       = local.namespace
  advanced_config = {}
  data = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name        = lower(var.instance_name)
      namespace   = local.namespace
      annotations = lookup(local.metadata, "annotations", {})
      labels      = lookup(local.metadata, "labels", {})
    }
    data = {
      for k, v in lookup(local.spec, "data", {}) : v.key => v.value
    }
  }
}
