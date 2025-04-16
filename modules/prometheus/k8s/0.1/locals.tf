locals {
  spec = lookup(var.instance, "spec", {})
  prometheusOperatorSpec = lookup(local.spec, "operator", {
    "enabled" = true
    "size" = {
      "cpu"    = "200m"
      "memory" = "512Mi"
    }
  })
  prometheusSpec = lookup(local.spec, "prometheus", {
    "enabled" = true
    "size" = {
      "cpu"    = "1000m"
      "memory" = "4Gi"
    }
  })
  alertmanagerSpec = lookup(local.spec, "alertmanager", {
    "enabled" = true
    "size" = {
      "cpu"    = "1000m"
      "memory" = "2Gi"
    }
  })

  grafanaSpec = lookup(local.spec, "grafana", {
    "enabled" = true
    "size" = {
      "cpu"    = "200m"
      "memory" = "512Mi"
    }
  })
  prometheus_retention = lookup(local.spec, "retention", "100d")
  helm_chart_version   = lookup(local.spec, "version", null)
}