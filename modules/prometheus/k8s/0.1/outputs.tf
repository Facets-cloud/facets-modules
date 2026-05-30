locals {
  output_interfaces = {}
  output_attributes = {
    prometheus_url   = "http://${module.name.name}.${var.environment.namespace}.svc.cluster.local:9090"
    alertmanager_url = "http://${module.name.name}-alertmanager.${var.environment.namespace}.svc.cluster.local:9093"
    helm_release_id  = helm_release.prometheus-operator.id
  }
}