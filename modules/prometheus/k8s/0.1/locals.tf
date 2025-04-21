locals {
  spec     = lookup(var.instance, "spec", {})
  metadata = lookup(var.instance, "metadata", {})

  prometheusOperatorSpec = lookup(local.spec, "operator", {
    "enabled" = true
    "size" = {
      "resources" = {
        "requests" = {
          "cpu"    = "200m"
          "memory" = "512Mi"
        }
        "limits" = {
          "cpu"    = "200m"
          "memory" = "512Mi"
        }
      }
    }
  })

  prometheusSpec = lookup(local.spec, "prometheus", {
    "enabled" = true
    "size" = {
      "resources" = {
        "requests" = {
          "cpu"    = "1000m"
          "memory" = "4Gi"
        }
        "limits" = {
          "cpu"    = "1000m"
          "memory" = "4Gi"
        }
      }
      "volume" = "100Gi"
    }
  })

  alertmanagerSpec = lookup(local.spec, "alertmanager", {
    "enabled" = true
    "size" = {
      "resources" = {
        "requests" = {
          "cpu"    = "1000m"
          "memory" = "2Gi"
        }
        "limits" = {
          "cpu"    = "1000m"
          "memory" = "2Gi"
        }
      }
      "volume" = "10Gi"
    }
  })

  grafanaSpec = lookup(local.spec, "grafana", {
    "enabled" = true
    "size" = {
      "resources" = {
        "requests" = {
          "cpu"    = "200m"
          "memory" = "512Mi"
        }
        "limits" = {
          "cpu"    = "200m"
          "memory" = "512Mi"
        }
      }
    }
  })

  kubeStateMetricsSpec = lookup(local.spec, "kube-state-metrics", {
    "enabled" = true
    "size" = {
      "resources" = {
        "requests" = {
          "cpu"    = null
          "memory" = null
        }
        "limits" = {
          "cpu"    = null
          "memory" = null
        }
      }
    }
  })

  valuesSpec = lookup(local.spec, "values", {})

  prometheus_retention = lookup(local.spec, "retention", "100d")
  tolerations = concat(lookup(var.environment, "default_tolerations", [{
    key      = "kubernetes.azure.com/scalesetpriority"
    value    = "spot"
    operator = "Equal"
    effect   = "NoSchedule"
  }]), lookup(local.spec, "tolerations", []))
  nodeSelector = {
    for label in values(lookup(local.spec, "node_selector", {})) :
    label.key => label.value
  }
  namespace = lookup(local.metadata, "namespace", var.environment.namespace)

  # Default values for the helm chart
  default_values = {
    fullnameOverride                   = module.name.name
    cleanPrometheusOperatorObjectNames = true
    crds = {
      enabled = lookup(local.spec, "enable_crds", true)
      upgradeJob = {
        enabled = true
      }
    }
    defaultRules = {
      create = false
    }
    prometheusOperator = {
      enabled = lookup(local.prometheusOperatorSpec, "enabled", true)
      tls = {
        enabled = false
      }
      admissionWebhooks = {
        enabled = false
      }
      resources = {
        requests = {
          cpu    = lookup(local.prometheusOperatorSpec.size.resources.requests, "cpu", "200m")
          memory = lookup(local.prometheusOperatorSpec.size.resources.requests, "memory", "512Mi")
        }
        limits = {
          cpu    = lookup(local.prometheusOperatorSpec.size.resources.limits, "cpu", "200m")
          memory = lookup(local.prometheusOperatorSpec.size.resources.limits, "memory", "512Mi")
        }
      }
      # priorityClassName = "facets-critical"
      nodeSelector = local.nodeSelector
      tolerations  = local.tolerations
    }
    prometheus = {
      enabled = lookup(local.prometheusSpec, "enabled", true)
      prometheusSpec = {
        enableRemoteWriteReceiver               = true
        ruleSelectorNilUsesHelmValues           = false
        serviceMonitorSelectorNilUsesHelmValues = false
        retention                               = local.prometheus_retention
        resources = {
          requests = {
            cpu    = lookup(local.prometheusSpec.size.resources.requests, "cpu", "1000m")
            memory = lookup(local.prometheusSpec.size.resources.requests, "memory", "4Gi")
          }
          limits = {
            cpu    = lookup(local.prometheusSpec.size.resources.limits, "cpu", "1000m")
            memory = lookup(local.prometheusSpec.size.resources.limits, "memory", "4Gi")
          }
        }
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
        additionalScrapeConfigs = [
          {
            job_name = "kubernetes-pods"
            kubernetes_sd_configs = [
              {
                role = "pod"
              }
            ]
            relabel_configs = [
              {
                action        = "keep"
                regex         = "true"
                source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
              },
              {
                action        = "replace"
                regex         = "(.+)"
                source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                target_label  = "__metrics_path__"
              },
              {
                action        = "replace"
                regex         = "([^:]+)(?::\\d+)?;(\\d+)"
                replacement   = "$1:$2"
                source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
                target_label  = "__address__"
              },
              {
                action = "labelmap"
                regex  = "__meta_kubernetes_pod_label_(.+)"
              },
              {
                action        = "replace"
                source_labels = ["__meta_kubernetes_namespace"]
                target_label  = "kubernetes_namespace"
              },
              {
                action        = "replace"
                source_labels = ["__meta_kubernetes_pod_name"]
                target_label  = "kubernetes_pod_name"
              }
            ]
          }
        ]
        walCompression = true
        # priorityClassName = "facets-critical"
      }
    }
    alertmanager = {
      enabled = lookup(local.alertmanagerSpec, "enabled", true)
      annotations = {
        "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
      }
      alertmanagerSpec = {
        resources = {
          requests = {
            cpu    = lookup(local.alertmanagerSpec.size.resources.requests, "cpu", "1000m")
            memory = lookup(local.alertmanagerSpec.size.resources.requests, "memory", "2Gi")
          }
          limits = {
            cpu    = lookup(local.alertmanagerSpec.size.resources.limits, "cpu", "1000m")
            memory = lookup(local.alertmanagerSpec.size.resources.limits, "memory", "2Gi")
          }
        }
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
        # priorityClassName = "facets-critical"
      }
      config = {
        global = {
          resolve_timeout = "60m"
        }
        route = {
          receiver        = "default"
          group_by        = ["alertname", "entity"]
          routes          = []
          group_wait      = "30s"
          group_interval  = "5m"
          repeat_interval = "6h"
        }
        receivers = [
          {
            name = "default"
            webhook_configs = [
              {
                url           = "http://alertmanager-webhook.default/alerts"
                send_resolved = true
              },
              {
                url           = "https://${var.cc_metadata.cc_host}/cc/v1/clusters/${var.environment.cloud_tags.facetsclusterid}/alerts"
                send_resolved = true
                http_config = {
                  bearer_token = var.cc_metadata.cc_auth_token
                }
              }
            ]
          }
        ]
      }
    }
    grafana = {
      enabled = lookup(local.grafanaSpec, "enabled", true)
      image = {
        tag = "9.2.15"
      }
      sidecar = {
        datasources = {
          defaultDatasourceEnabled = false
        }
      }
      podAnnotations = {
        "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
      }
      resources = {
        requests = {
          cpu    = lookup(local.grafanaSpec.size.resources.requests, "cpu", "200m")
          memory = lookup(local.grafanaSpec.size.resources.requests, "memory", "512Mi")
        }
        limits = {
          cpu    = lookup(local.grafanaSpec.size.resources.limits, "cpu", "200m")
          memory = lookup(local.grafanaSpec.size.resources.limits, "memory", "512Mi")
        }
      }
      nodeSelector             = local.nodeSelector
      tolerations              = local.tolerations
      defaultDashboardsEnabled = false
      "grafana.ini" = {
        security = {
          allow_embedding = true
        }
        server = {
          root_url            = "%(protocol)s://%(domain)s:%(http_port)s/tunnel/${var.environment.cloud_tags.facetsclusterid}/grafana/"
          serve_from_sub_path = true
        }
        "auth.anonymous" = {
          enabled  = true
          org_name = "Main Org."
          org_role = "Editor"
        }
      }
      imageRenderer = {
        enabled = true
        image = {
          repository = "hferreira/grafana-image-renderer"
        }
        podAnnotations = {
          "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
        }
        # priorityClassName = "facets-critical"
        nodeSelector = local.nodeSelector
        tolerations  = local.tolerations
      }
      # priorityClassName = "facets-critical"
    }
    "kube-state-metrics" = {
      enabled = lookup(local.kubeStateMetricsSpec, "enabled", true)
      collectors = distinct(concat([
        "certificatesigningrequests", "configmaps", "cronjobs", "daemonsets", "deployments",
        "endpoints", "horizontalpodautoscalers", "verticalpodautoscalers", "ingresses", "jobs",
        "leases", "limitranges", "mutatingwebhookconfigurations", "namespaces", "networkpolicies",
        "nodes", "persistentvolumeclaims", "persistentvolumes", "poddisruptionbudgets", "pods",
        "replicasets", "replicationcontrollers", "resourcequotas", "secrets", "services",
        "statefulsets", "storageclasses", "validatingwebhookconfigurations", "volumeattachments"
      ], lookup(local.kubeStateMetricsSpec, "collectors", [])))
      extraArgs = [
        "--metric-labels-allowlist=pods=[*],nodes=[*],ingresses=[*]"
      ]
      # priorityClassName = "facets-critical"
      nodeSelector = local.nodeSelector
      tolerations  = local.tolerations
    }
    "prometheus-node-exporter" = {
      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }
      # priorityClassName = "facets-critical"
    }
  }

  irsa_config = {
    enabled              = var.environment.cloud == "AWS" ? 1 : 0
    service_account_name = "facets-${module.name.name}-ec2-ro-sa"
  }

  # EC2 scrape config for IRSA if enabled
  ec2_scrape_config = local.irsa_config.enabled == 1 ? [{
    job_name = "ec2-instances"
    ec2_sd_configs = [
      {
        port   = 9100
        region = var.environment.region
        filters = [
          {
            name   = "tag:facetsclustername"
            values = [var.environment.cloud_tags.facetsclustername]
          },
          {
            name   = "tag:facetsresourcetype"
            values = ["aws_vm"]
          }
        ]
      }
    ]
    relabel_configs = [
      {
        action = "labelmap"
        regex  = "__meta_ec2_(ami|architecture|availability_zone|instance_id|private_dns_name|region)"
      },
      {
        action = "labelmap"
        regex  = "__meta_ec2_tag_(.+)"
      }
    ]
  }] : []

  # Conditionally add IRSA config
  service_account_config = local.irsa_config.enabled == 1 ? {
    prometheus = {
      serviceAccount = {
        create = true
        name   = local.irsa_config.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = module.irsa[0].iam_role_arn
        }
      }
    }
  } : {}
}
