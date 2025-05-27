locals {
  output_interfaces = {
    prometheus = {
      endpoint = "http://${module.name.name}-prometheus.${local.namespace}.svc.cluster.local:9090"
      host     = "${module.name.name}-prometheus.${local.namespace}.svc.cluster.local"
      port     = 9090
    }
    alertmanager = {
      endpoint = "http://${module.name.name}-alertmanager.${local.namespace}.svc.cluster.local:9093"
      host     = "${module.name.name}-alertmanager.${local.namespace}.svc.cluster.local"
      port     = 9093
    }
    grafana = lookup(local.grafanaSpec, "enabled", false) ? {
      endpoint = "http://${module.name.name}-grafana.${local.namespace}.svc.cluster.local:80"
      host     = "${module.name.name}-grafana.${local.namespace}.svc.cluster.local"
      port     = 80
    } : {}
  }
  output_attributes = {
    prometheus = {
      endpoint = "http://${module.name.name}-prometheus.${local.namespace}.svc.cluster.local:9090"
      host     = "${module.name.name}-prometheus.${local.namespace}.svc.cluster.local"
      port     = 9090
    }
    alertmanager = {
      endpoint = "http://${module.name.name}-alertmanager.${local.namespace}.svc.cluster.local:9093"
      host     = "${module.name.name}-alertmanager.${local.namespace}.svc.cluster.local"
      port     = 9093
    }
    grafana = lookup(local.grafanaSpec, "enabled", false) ? {
      endpoint = "http://${module.name.name}-grafana.${local.namespace}.svc.cluster.local:80"
      host     = "${module.name.name}-grafana.${local.namespace}.svc.cluster.local"
      port     = 80
    } : {}
  }
}
