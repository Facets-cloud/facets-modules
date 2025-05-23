locals {
  spec           = lookup(var.instance, "spec", {})
  cloud_account  = lookup(local.spec, "cloud_account", null)
  cloud_provider = lookup(local.spec, "cloud_provider", null)
}
