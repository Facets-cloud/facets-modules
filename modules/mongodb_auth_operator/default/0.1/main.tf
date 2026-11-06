resource "helm_release" "mongodb-auth-operator" {
  name             = "mongodb-auth-operator"
  repository       = "https://facets-cloud.github.io/helm-charts"
  chart            = "mongodb-auth-operator"
  version          = lookup(local.mongodb_auth_operator, "version", "0.1.1")
  cleanup_on_fail  = lookup(local.mongodb_auth_operator, "cleanup_on_fail", true)
  namespace        = local.namespace
  create_namespace = lookup(local.mongodb_auth_operator, "create_namespace", false)
  wait             = lookup(local.mongodb_auth_operator, "wait", false)
  atomic           = lookup(local.mongodb_auth_operator, "atomic", false)
  timeout          = lookup(local.mongodb_auth_operator, "timeout", 600)
  recreate_pods    = lookup(local.mongodb_auth_operator, "recreate_pods", false)

  values = [
    <<VALUES
controllerManager:
  manager:
    resources:
      limits:
        cpu: ${local.cpu_limit}
        memory: ${local.memory_limit}
      requests:
        cpu: 10m
        memory: 64Mi
VALUES
    , yamlencode({
      tolerations  = concat(var.environment.default_tolerations, local.facets_dedicated_tolerations)
      nodeSelector = local.facets_dedicated_node_selectors
    }),
    yamlencode({
      imagePullSecrets = var.inputs.kubernetes_details.attributes.legacy_outputs.registry_secret_objects
    }),
    # kube-rbac-proxy: gcr.io/kubebuilder is sunset (kubebuilder discussions/3907).
    # Inject quay.io via values (provider-version-agnostic; same convention as the
    # blocks above). Placed before user values so an explicit user override still wins;
    # still overrides the chart's gcr default regardless of the pinned chart version.
    yamlencode({
      controllerManager = {
        kubeRbacProxy = {
          image = {
            repository = "quay.io/brancz/kube-rbac-proxy"
            tag        = "v0.13.1"
          }
        }
      }
    }),
    yamlencode(local.user_supplied_helm_values)
  ]
}
