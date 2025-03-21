locals {
  namespace                       = lookup(lookup(var.instance, "metadata", {}), "namespace", "facets")
  spec                            = lookup(var.instance, "spec", {})
  advanced                        = lookup(var.instance, "advanced", {})
  image_pull_secret_injector      = lookup(local.advanced, "image_pull_secret_injector", {})
  user_supplied_helm_values       = lookup(local.spec, "values", {})
  size                            = lookup(local.spec, "size", {})
  cpu_limit                       = lookup(local.size, "cpu_limit", "200m")
  memory_limit                    = lookup(local.size, "memory_limit", "1000Mi")
  facets_dedicated_tolerations    = lookup(lookup(lookup(lookup(var.inputs, "kubernetes_details", {}), "attributes", {}), "legacy_outputs", {}), "facets_dedicated_tolerations", lookup(var.environment, "facets_dedicated_tolerations", []))
  facets_dedicated_node_selectors = lookup(lookup(lookup(lookup(var.inputs, "kubernetes_details", {}), "attributes", {}), "legacy_outputs", {}), "facets_dedicated_node_selectors", lookup(var.environment, "facets_dedicated_node_selectors", {}))
  dockerhub_secret_objects        = lookup(lookup(lookup(var.inputs, "artifactories", {}), "attributes", {}), "registry_secret_objects", {})
  secret_list = join(",", [
    for k, v in local.dockerhub_secret_objects : v[0].name
  ])
  cluster_id = lookup(lookup(lookup(lookup(lookup(var.inputs, "kubernetes_details", {}), "attributes", {}), "legacy_outputs", {}), "k8s_details", {}), "cluster_id", "")
}
