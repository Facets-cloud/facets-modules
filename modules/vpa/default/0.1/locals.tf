# Define your locals here
locals {
  spec = var.instance.spec

  # VPA Configuration
  vpa_version      = local.spec.version
  vpa_namespace    = local.spec.namespace
  create_namespace = local.spec.create_namespace

  # Deployment Configuration
  deployment      = local.spec.deployment
  cleanup_on_fail = local.deployment.cleanup_on_fail
  wait            = local.deployment.wait
  atomic          = local.deployment.atomic
  timeout         = local.deployment.timeout
  recreate_pods   = local.deployment.recreate_pods

  # Recommender Configuration
  recommender         = local.spec.recommender
  recommender_enabled = local.recommender.enabled
  storage             = try(local.recommender.storage, "prometheus")

  # Get Prometheus URL from prometheus module output if available and storage is prometheus
  prometheus_address = (local.storage == "prometheus" && var.inputs.prometheus_details != null) ? var.inputs.prometheus_details.attributes.prometheus_url : "http://prometheus-operator-prometheus.default.svc.cluster.local:9090"

  # Resource sizing
  requests = {
    cpu    = local.recommender.size.cpu
    memory = local.recommender.size.memory
  }
  limits = {
    cpu    = local.recommender.size.cpu_limits
    memory = local.recommender.size.memory_limits
  }

  # Additional recommender configuration
  recommender_configuration = merge(
    {
      "prometheus-address"    = local.prometheus_address
      "storage"               = local.storage
      "metric-for-pod-labels" = "kube_pod_labels{job=\"kube-state-metrics\"}[8d]"
      "pod-namespace-label"   = "namespace"
      "pod-name-label"        = "pod"
    },
    try(local.recommender.configuration, {})
  )

  # Updater and Admission Controller
  updater_enabled              = local.spec.updater.enabled
  admission_controller_enabled = local.spec.admission_controller.enabled

  # Custom Helm values
  user_supplied_helm_values = try(local.spec.helm_values, {})

  # Nodepool configuration from inputs
  nodepool_config = lookup(var.inputs, "kubernetes_node_pool_details", null) != null ? var.inputs.kubernetes_node_pool_details.attributes : {
    node_class_name = ""
    node_pool_name  = ""
    taints          = []
    node_selector   = {}
  }
  nodepool_tolerations = lookup(local.nodepool_config, "taints", [])
  nodepool_labels      = lookup(local.nodepool_config, "node_selector", {})

  # Use nodepool configuration if available, otherwise use default tolerations
  tolerations  = length(local.nodepool_tolerations) > 0 ? local.nodepool_tolerations : try(var.environment.default_tolerations, [])
  nodeSelector = local.nodepool_labels
}