# Define your locals here
locals {
  metadata           = lookup(var.instance, "metadata", {})
  spec               = lookup(var.instance, "spec", {})
  advanced_config    = lookup(lookup(var.instance, "advanced", {}), "k8s", {})
  skip_base64_encode = lookup(local.spec, "skip_base64_encode", false)
  namespace          = lookup(local.metadata, "namespace", null) == null ? var.environment.namespace : var.instance.metadata.namespace
}
