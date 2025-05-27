# Define your locals here
locals {
  metadata        = lookup(var.instance, "metadata", {})
  spec            = lookup(var.instance, "spec", {})
  advanced_config = lookup(lookup(var.instance, "advanced", {}), "k8s", {})
  namespace       = lookup(local.metadata, "namespace", null) == null ? var.environment.namespace : var.instance.metadata.namespace
}
