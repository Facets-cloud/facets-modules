locals {
  namespace                       = lookup(lookup(var.instance, "metadata", {}), "namespace", "facets")
  spec                            = lookup(var.instance, "spec", {})
  advanced                        = lookup(var.instance, "advanced", {})
  database_operator               = lookup(local.advanced, "database_operator", {})
  user_supplied_helm_values       = lookup(local.spec, "values", {})
  size                            = lookup(local.spec, "size", {})
  cpu_limit                       = lookup(local.size, "cpu_limit", "200m")
  memory_limit                    = lookup(local.size, "memory_limit", "1000Mi")
  facets_dedicated_tolerations    = lookup(lookup(lookup(lookup(var.inputs, "kubernetes_details", {}), "attributes", {}), "legacy_outputs", {}), "facets_dedicated_tolerations", lookup(var.environment, "facets_dedicated_tolerations", []))
  facets_dedicated_node_selectors = lookup(lookup(lookup(lookup(var.inputs, "kubernetes_details", {}), "attributes", {}), "legacy_outputs", {}), "facets_dedicated_node_selectors", lookup(var.environment, "facets_dedicated_node_selectors", {}))
}
