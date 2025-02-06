resource "helm_release" "crossplane" {
  name             = "crossplane"
  repository       = "https://charts.crossplane.io/stable"
  chart            = "crossplane"
  version          = lookup(local.crossplane, "version", "1.11.0")
  cleanup_on_fail  = lookup(local.crossplane, "cleanup_on_fail", true)
  namespace        = local.namespace
  create_namespace = lookup(local.crossplane, "create_namespace", false)
  wait             = lookup(local.crossplane, "wait", false)
  atomic           = lookup(local.crossplane, "atomic", false)
  timeout          = lookup(local.crossplane, "timeout", 600)
  recreate_pods    = lookup(local.crossplane, "recreate_pods", false)

  values = [
    <<VALUES
provider:
  packages:
  - "crossplane/provider-sql:v0.7.0"
metrics:
  enabled: true
resourcesCrossplane:
  limits:
    cpu: ${local.cpu_limit}
    memory: ${local.memory_limit}
  requests:
    cpu: "100m"
    memory: "256Mi"
resourcesRBACManager:
  limits:
    cpu: ${local.cpu_limit}
    memory: ${local.memory_limit}
  requests:
    cpu: "100m"
    memory: "256Mi"
VALUES
    , yamlencode(
      {
        tolerations  = concat(var.environment.default_tolerations, var.environment.facets_dedicated_tolerations)
        nodeSelector = var.environment.facets_dedicated_node_selectors
        rbacManager = {
          tolerations  = concat(var.environment.default_tolerations, var.environment.facets_dedicated_tolerations)
          nodeSelector = var.environment.facets_dedicated_node_selectors
        }
  }), yamlencode(local.user_supplied_helm_values)]
}
