# Define your terraform resources here

resource "kubernetes_namespace" "vpa_namespace" {
  count = local.create_namespace ? 1 : 0
  metadata {
    name = local.vpa_namespace
    labels = merge(
      {
        "name"                       = local.vpa_namespace
        "facets.cloud/instance-name" = var.instance_name
      },
      var.environment.cloud_tags
    )
  }
}

resource "helm_release" "vpa" {
  name             = var.instance_name
  chart            = "vpa"
  repository       = "https://charts.fairwinds.com/stable/"
  version          = local.vpa_version
  cleanup_on_fail  = local.cleanup_on_fail
  namespace        = local.vpa_namespace
  create_namespace = false
  wait             = local.wait
  atomic           = local.atomic
  timeout          = local.timeout
  recreate_pods    = local.recreate_pods

  depends_on = [
    kubernetes_namespace.vpa_namespace
  ]

  values = [
    <<VALUES
prometheus_id: ${try(var.inputs.prometheus_details.attributes.helm_release_id, "")}
priorityClassName: facets-critical
recommender:
  enabled: ${local.recommender_enabled}
  extraArgs:
    prometheus-address: |
      ${local.prometheus_address}
    storage: ${local.storage}
    metric-for-pod-labels: kube_pod_labels{job="kube-state-metrics"}[8d]
    pod-namespace-label: namespace
    pod-name-label: pod
updater:
  enabled: ${local.updater_enabled}
admissionController:
  enabled: ${local.admission_controller_enabled}
VALUES
    , yamlencode({
      recommender = {
        resources = {
          requests = local.requests
          limits   = local.limits
        }
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
        extraArgs    = local.recommender_configuration
      }
      updater = {
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
      }
      admissionController = {
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
      }
    }), yamlencode(local.user_supplied_helm_values)
  ]
}