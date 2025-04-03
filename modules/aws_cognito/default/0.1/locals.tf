locals {
  spec = lookup(var.instance, "spec", {})
  is_custom_user_pool_name = length(lookup(local.spec, "user_pool_name", {})) > 0
}
