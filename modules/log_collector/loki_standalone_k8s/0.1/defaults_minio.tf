locals {
  minio_random_password      =  try(random_password.minio_password[0].result, null)
  minio_instance_name = "${local.instance_name}-minio"
  default_minio = {
    mode             = "standalone"
    fullnameOverride = local.minio_instance_name
    enabled          = local.is_minio_enabled
    replicas         = local.minio_replica
    drivesPerNode    = 2
    rootUser         = local.minio_username
    rootPassword     = lookup(lookup(local.minio, "auth", {}), "rootPassword", local.minio_random_password)
    buckets = [
      {
        name   = "chunks"
        policy = "none"
        purge  = false
      },
      {
        name   = "ruler"
        policy = "none"
        purge  = false
      },
      {
        name   = "admin"
        policy = "none"
        purge  = false
      }
    ]
    persistence = {
      size = local.minio_volume
    }
    image = {
      registry   = "docker.io"
      repository = "bitnamilegacy/minio"
    }
    volumePermissions = {
      image = {
        registry   = "docker.io"
        repository = "bitnamilegacy/os-shell"
        tag        = "11-debian-11-r90"
      }
    }
    metrics = {
      serviceMonitor = {
        enabled = true
      }
    }
    tolerations  = local.tolerations
    nodeSelector = local.node_selectors
    podLabels    = local.loki_podLabels
    resources = {
      requests = {
        memory = "100Mi"
        cpu    = "100m"
      }
      limits = {
        memory = "500Mi"
        cpu    = "200m"
      }
    }
    postJob = {
      tolerations  = local.tolerations
      nodeSelector = local.node_selectors
    }
    address = null
  }
}
