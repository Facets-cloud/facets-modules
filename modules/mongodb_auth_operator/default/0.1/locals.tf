locals {
  namespace                 = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  spec                      = lookup(var.instance, "spec", {})
  advanced                  = lookup(var.instance, "advanced", {})
  mongodb_auth_operator     = lookup(local.advanced, "mongo_auth_operator", {})
  user_supplied_helm_values = lookup(local.mongodb_auth_operator, "values", {})
  size                      = lookup(local.spec, "size", {})
  cpu_limit                 = lookup(local.size, "cpu_limit", "200m")
  memory_limit              = lookup(local.size, "memory_limit", "1000Mi")
}
