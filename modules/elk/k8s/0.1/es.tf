locals {
  es = {
    apiVersion = "elasticsearch.k8s.elastic.co/v1"
    kind       = "Elasticsearch"
    metadata = {
      name      = "${module.name.name}-es"
      namespace = local.namespace
    }
    spec = {
      version = lookup(local.elasticsearch_spec, "version", "8.15.0")
      image   = lookup(local.elasticsearch_spec, "image", null)
      http    = lookup(local.elasticsearch_spec, "http", {})
      nodeSets = concat([
        {
          name = "default"
          config = {
            "node.roles"            = ["master", "data", "ingest"]
            "node.attr.attr_name"   = "attr_value"
            "node.store.allow_mmap" = false
          }
          podTemplate = {
            metadata = {
              labels = {
                name = "${module.name.name}-es"
              }
            }
            spec = {
              containers = [
                {
                  name = "elasticsearch"
                  resources = {
                    requests = {
                      memory = local.elasticsearch_spec.memory
                      cpu    = local.elasticsearch_spec.cpu
                    }
                    limits = {
                      memory = lookup(local.elasticsearch_spec, "memory_limit", local.elasticsearch_spec.memory)
                      cpu    = lookup(local.elasticsearch_spec, "cpu_limit", local.elasticsearch_spec.cpu)
                    }
                  }
                }
              ]
              tolerations = local.tolerations
            }
          }
          count = lookup(local.elasticsearch_spec, "instance_count", 3)
        }
      ], lookup(local.elasticsearch_spec, "nodeSets", []))
      auth                    = lookup(local.elasticsearch_spec, "auth", {})
      monitoring              = lookup(local.elasticsearch_spec, "monitoring", {})
      secureSettings          = lookup(local.elasticsearch_spec, "secureSettings", [])
      podDisruptionBudget     = lookup(local.elasticsearch_spec, "podDisruptionBudget", {})
      revisionHistoryLimit    = lookup(local.elasticsearch_spec, "revisionHistoryLimit", 5)
      volumeClaimDeletePolicy = lookup(local.elasticsearch_spec, "volumeClaimDeletePolicy", "DeleteOnScaledownAndClusterDeletion")
    }
  }
  es_volume = local.elasticsearch_spec.volume
}