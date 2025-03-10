locals {
  spec             = lookup(var.instance, "spec", {})
  advanced         = lookup(var.instance, "advanced", {})
  tags             = merge(var.environment.cloud_tags, lookup(local.spec, "tags", {}))
  region           = var.environment.region
}