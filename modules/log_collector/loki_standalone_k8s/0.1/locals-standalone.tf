locals {
  loki_pvc_label = {
    "app.kubernetes.io/component" = "single-binary"
    "app.kubernetes.io/instance"  = local.instance_name
    "app.kubernetes.io/name"      = "loki"
  }
  loki_podLabels = {
    resourceName = local.instance_name
    resourceType = "log_collector"
  }
  minio_pvc_names = flatten([
    for i in range(local.minio_pvc_count) : [
      for j in range(local.minio_replica) : "export-${i}-${local.instance_name}-minio-${j}"
    ]
  ])
  loki_standalone = {
    nameOverride = local.instance_name
    loki = {
      podLabels    = local.loki_podLabels
      auth_enabled = false,
      commonConfig = {
        replication_factor = local.replicas
      }

      schemaConfig = {
        configs = [
          {
            from         = "2024-04-01"
            store        = "tsdb"
            object_store = "s3"
            schema       = "v13"
            index = {
              prefix = "loki_index_"
              period = "24h"
            }
          }
        ]
      }

      pattern_ingester = {
        enabled = true
      }

      limits_config = {
        allow_structured_metadata = true
        volume_enabled            = true
      }

      ruler = {
        enabled = false
        enable_api = true
      }
    }

    minio = local.default_minio


    deploymentMode = "SingleBinary"
    singleBinary = {
      replicas = local.replicas
      size     = local.loki_volume
      resources = {
        requests = {
          memory = "100Mi"
          cpu    = "100m"
        }
        limits = {
          memory = "500Mi"
          cpu    = "300m"
        }
      }
      tolerations  = local.tolerations
      nodeSelector = local.node_selectors
    }
    lokiCanary = {
      enabled = false
    }

    test = {
      enabled = false
    }
    chunksCache = {
      enabled      = false
      tolerations  = local.tolerations
      nodeSelector = local.node_selectors
    }
    resultsCache = {
      enabled      = false
      tolerations  = local.tolerations
      nodeSelector = local.node_selectors
    }
    gateway = {
      tolerations  = local.tolerations
      nodeSelector = local.node_selectors
    }

    # Zero out replica counts of other deployment modes
    backend = {
      replicas = 0
    }

    read = {
      replicas = 0
    }

    write = {
      replicas = 0
    }

    ingester = {
      replicas = 0
    }

    querier = {
      replicas = 0
    }

    queryFrontend = {
      replicas = 0
    }

    queryScheduler = {
      replicas = 0
    }

    distributor = {
      replicas = 0
    }

    compactor = {
      replicas = 0
    }

    indexGateway = {
      replicas = 0
    }

    bloomCompactor = {
      replicas = 0
    }

    bloomGateway = {
      replicas = 0
    }
  }
}
