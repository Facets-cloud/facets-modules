# Define your locals here
locals {
  advanced_config = lookup(lookup(var.instance, "advanced", {}), "status_check", {})
  metadata        = lookup(var.instance, "metadata", {})
  namespace       = lookup(local.metadata, "namespace", var.environment.namespace)
  spec            = lookup(var.instance, "spec", {})
  resource_name   = lookup(local.metadata, "name", lower(var.instance_name))
  processed_names = {
    for key, value in local.spec : key => {
      for k, v in value : lower("${var.instance_name}-${key}-${k}") => merge({ check_type = key }, v) if !lookup(v, "disabled", false)
    } if !lookup(value, "disabled", false)
  }
  # checks = merge(values(local.processed_names)...)
}
