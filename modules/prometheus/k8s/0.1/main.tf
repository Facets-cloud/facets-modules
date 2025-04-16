resource "helm_release" "prometheus-operator" {
  name       = var.instance_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace       = var.environment.namespace
  version =  lookup(local.spec, "version", null)
  cleanup_on_fail = true

  set {
    name  = "crds.upgradeJob.enabled"
    value = "true"
  }

  set {
    name = "fullnameOverride"
    value = var.instance_name
  }

  set {
    name = "prometheusOperator.admissionWebhooks.enabled"
    value = false
  }

  set {
    name  = "prometheusOperator.tls.enabled"
    value = false
  }

  set {
    name = "prometheusOperator.tlsProxy.enabled"
    value = false
  }

  set {
    name = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = false
  }

  set {
    name = "prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues"
    value = false
  }

  set {
    name = "prometheus.prometheusSpec.retention"
    value = lookup(local.spec, "retention", "100d")
  }

  set {
    name = "prometheus.prometheusSpec.walCompression"
    value = true
  }

  set {
    name = "defaultRules.create"
    value = false
  }
  set {
    name = "prometheusOperator.resources.requests.cpu"
    value = local.prometheusOperatorSpec.size.cpu
  }

  set {
    name = "prometheusOperator.resources.requests.memory"
    value = local.prometheusOperatorSpec.size.memory
  }

  set {
    name = "prometheus.prometheusSpec.resources.requests.cpu"
    value = local.prometheusSpec.size.cpu
  }

  set {
    name = "prometheus.prometheusSpec.resources.requests.memory"
    value = local.prometheusSpec.size.memory
  }

  set {
    name = "alertmanager.alertmanagerSpec.resources.requests.cpu"
    value = local.alertmanagerSpec.size.cpu
  }

  set {
    name = "alertmanager.alertmanagerSpec.resources.requests.memory"
    value = local.alertmanagerSpec.size.memory
  }

  set {
    name = "grafana.resources.requests.cpu"
    value = local.grafanaSpec.size.cpu
  }

  set {
    name = "grafana.resources.requests.memory"
    value = local.grafanaSpec.size.memory
  }

  values = [
    <<AM_CONFIG
prometheus:
  prometheusSpec:
    nodeSelector:
      facets-node-type: "facets-dedicated"
    tolerations:
    - operator: "Exists"
    additionalScrapeConfigs:
    - job_name: kubernetes-pods
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scrape
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_pod_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: kubernetes_namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: kubernetes_pod_name
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: cap-expandable-storage
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
grafana:
  image:
    tag: 9.2.6
  tolerations:
  - operator: "Exists"
  defaultDashboardsEnabled: false
  grafana.ini:
    security:
      allow_embedding: true
    server:
      root_url: "%(protocol)s://%(domain)s:%(http_port)s/tunnel/${var.cluster.id}/grafana/"
      serve_from_sub_path: true
    auth.anonymous:
      enabled: true
      org_name: Main Org.
      org_role: Editor
  podAnnotations:
    "cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
prometheusOperator:
  tolerations:
  - operator: "Exists"
kube-state-metrics:
  tolerations:
  - operator: "Exists"
  extraArgs:
  - --metric-labels-allowlist=pods=[*]
alertmanager:
  alertmanagerSpec:
    tolerations:
    - operator: "Exists"
    nodeSelector:
      facets-node-type: "facets-dedicated"
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
  config:
    global:
      resolve_timeout: 60m
    route:
      receiver: 'default'
      group_by: ['alertname', 'entity']
      routes: []
      group_wait: 30s
      group_interval: 30m
      repeat_interval: 6h
    receivers:
    - name: "default"
      webhook_configs:
      - url: "http://alertmanager-webhook.default/alerts"
        send_resolved: true
      - url: "https://${var.cc_metadata.cc_host}/cc/v1/clusters/${var.cluster.id}/alerts"
        send_resolved: false
        http_config:
          bearer_token: ${var.cc_metadata.cc_auth_token}
AM_CONFIG
  ]
}
