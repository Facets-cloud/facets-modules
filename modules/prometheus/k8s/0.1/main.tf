module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = true
  globally_unique = false
  resource_type   = "prometheus"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 45
}

# Deploy kube-prometheus-stack
resource "helm_release" "prometheus-operator" {
  depends_on = [module.prometheus-pvc, module.alertmanager-pvc]
  wait       = true
  name       = module.name.name
  repository = "https://prometheus-community.github.io/helm-charts"
  # version         = "43.2.1"
  chart           = "kube-prometheus-stack"
  namespace       = local.namespace
  cleanup_on_fail = true

  values = [
    # Merge default values with user-provided values and EC2 scrape config if needed
    yamlencode(merge(
      local.default_values,
      # Add EC2 scrape config if IRSA is enabled
      local.irsa_config.enabled == 1 ? {
        prometheus = {
          prometheusSpec = {
            additionalScrapeConfigs = concat(
              local.default_values.prometheus.prometheusSpec.additionalScrapeConfigs,
              local.ec2_scrape_config
            )
          }
        }
      } : {},
      # Add storage configuration using the PVC utility module
      {
        prometheus = {
          prometheusSpec = {
            storageSpec = {
              volumeClaimTemplate = {
                metadata = {
                  name = "pvc"
                }
                spec = {
                  # Use existing PVC
                  # volumeName  = module.prometheus-pvc.pvc_name
                  volumeName  = "pvc"
                  accessModes = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = lookup(local.prometheusSpec.size, "volume", "100Gi")
                    }
                  }
                }
              }
            }
          }
        },
        alertmanager = {
          alertmanagerSpec = {
            storage = {
              volumeClaimTemplate = {
                metadata = {
                  name = "pvc"
                }
                spec = {
                  # Use existing PVC
                  # volumeName  = module.alertmanager-pvc.pvc_name
                  volumeName  = "pvc"
                  accessModes = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = lookup(local.alertmanagerSpec.size, "volume", "10Gi")
                    }
                  }
                }
              }
            }
          }
        },
        kube-state-metrics = {
          enabled = true
        },
      },
      # Add service account config for IRSA if enabled
      local.service_account_config,
      # Add user-provided values from spec.values
      local.valuesSpec
    ))
  ]
}

# Deploy Pushgateway
resource "helm_release" "prometheus-pushgateway" {
  depends_on = [helm_release.prometheus-operator]
  name       = "${module.name.name}-pushgateway"
  chart      = "prometheus-pushgateway"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = local.namespace
  # version         = "2.0.2"
  wait            = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      podAnnotations = {
        "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
      }
      resources = {
        limits = {
          memory = "512Mi"
          cpu    = "100m"
        }
      }
      serviceMonitor = {
        enabled   = true
        namespace = local.namespace
      }
      priorityClassName = "facets-critical"
      nodeSelector      = local.nodeSelector
      tolerations       = local.tolerations
    })
  ]
}
