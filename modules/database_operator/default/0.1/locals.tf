locals {
  namespace                 = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  spec                      = lookup(var.instance, "spec", {})
  advanced                  = lookup(var.instance, "advanced", {})
  database_operator         = lookup(local.advanced, "database_operator", {})
  user_supplied_helm_values = lookup(local.database_operator, "values", {})
  size                      = lookup(local.spec, "size", {})
  cpu_limit                 = lookup(local.size, "cpu_limit", "200m")
  memory_limit              = lookup(local.size, "memory_limit", "1000Mi")
}
