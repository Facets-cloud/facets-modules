# Define your locals here
locals {
  metadata              = lookup(var.instance, "metadata", {})
  spec                  = lookup(var.instance, "spec", {})
  user_defined_tags     = lookup(local.metadata, "tags", {})
  advanced              = lookup(lookup(var.instance, "advanced", {}), "secret_manager", {})
  override_default_name = lookup(local.spec, "override_default_name", false)
  override_name         = lookup(local.spec, "override_name", "")
  secrets               = lookup(local.spec, "secrets", {})
}