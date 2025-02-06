locals {
  namespace                 = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  spec                      = lookup(var.instance, "spec", {})
  advanced                  = lookup(var.instance, "advanced", {})
  crossplane                = lookup(local.advanced, "crossplane", {})
  user_supplied_helm_values = lookup(local.crossplane, "values", {})
  size                      = lookup(local.spec, "size", {})
  cpu_limit                 = lookup(local.size, "cpu_limit", "200m")
  memory_limit              = lookup(local.size, "memory_limit", "1000Mi")
}
