module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 64
  resource_name   = local.cluster_id != "" ? "${local.cluster_id}-${var.instance_name}" : var.instance_name
  resource_type   = "image_pull_secret_injector"
  globally_unique = false
  is_k8s          = true
}

resource "helm_release" "image-pull-secret-injector" {
  name             = module.name.name
  repository       = "https://facets-cloud.github.io/helm-charts"
  chart            = "image-pull-secret-injector"
  version          = lookup(local.image_pull_secret_injector, "version", "0.1.3")
  cleanup_on_fail  = lookup(local.image_pull_secret_injector, "cleanup_on_fail", true)
  namespace        = local.namespace
  create_namespace = lookup(local.image_pull_secret_injector, "create_namespace", false)
  wait             = lookup(local.image_pull_secret_injector, "wait", false)
  atomic           = lookup(local.image_pull_secret_injector, "atomic", false)
  timeout          = lookup(local.image_pull_secret_injector, "timeout", 600)
  recreate_pods    = lookup(local.image_pull_secret_injector, "recreate_pods", false)

  values = [
    <<VALUES
resources:
  limits:
    cpu: ${local.cpu_limit}
    memory: ${local.memory_limit}
  requests:
    cpu: 100m
    memory: 128Mi
VALUES
    , yamlencode({
      tolerations  = concat(var.environment.default_tolerations, local.facets_dedicated_tolerations)
      nodeSelector = local.facets_dedicated_node_selectors
    }),
    yamlencode({
      secretList = local.secret_list
    }),
    yamlencode(local.user_supplied_helm_values)
  ]
}
