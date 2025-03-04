locals {
  kibana = {
    apiVersion = "kibana.k8s.elastic.co/v1"
    kind       = "Kibana"
    metadata = {
      name      = "${module.name.name}-kibana"
      namespace = local.namespace
    }

    spec = {
      version = lookup(local.kibana_spec, "version", "8.15.0")
      image   = lookup(local.kibana_spec, "image", null)
      count   = lookup(local.kibana_spec, "instance_count", 1)
      elasticsearchRef = {
        name = lookup(local.kibana_spec, "elasticsearchRef_name", "${module.name.name}-es")
      }
      http           = lookup(local.kibana_spec, "http", {})
      monitoring     = lookup(local.kibana_spec, "monitoring", {})
      secureSettings = lookup(local.kibana_spec, "secureSettings", [])
      podTemplate = lookup(local.kibana_spec, "podTemplate", {
        metadata = {
          labels = {
            name = "${module.name.name}-kibana"
          }
        }
        spec = {
          containers = [
            {
              name = "kibana"
              resources = {
                requests = {
                  memory = local.kibana_spec.memory
                  cpu    = local.kibana_spec.cpu
                }
                limits = {
                  memory = lookup(local.kibana_spec, "memory_limit", local.kibana_spec.memory)
                  cpu    = lookup(local.kibana_spec, "cpu_limit", local.kibana_spec.cpu)
                }
              }
            }
          ]
          tolerations = local.tolerations
        }
      })
      revisionHistoryLimit = lookup(local.kibana_spec, "revisionHistoryLimit", 5)
    }
  }
}