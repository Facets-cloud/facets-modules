locals {
  name                      = module.name.name
  spec                      = lookup(var.instance, "spec", {})
  cluster                   = lookup(local.spec, "cluster", {})
  node_pools                = lookup(local.spec, "node_pools", {})
  default_node_pool         = lookup(local.node_pools, "default", {})
  dedicated_node_pool       = lookup(local.node_pools, "dedicated", {})
  default_reclaim_policy    = lookup(local.cluster, "default_reclaim_policy", "Delete")
  namespace                 = lookup(var.cluster, "namespace", "default")
  user_supplied_helm_values = lookup(local.secret_copier, "values", {})
  secret_copier             = lookup(local.spec, "secret-copier", {})
  cloud_tags = {
    facetscontrolplane = split(".", var.cc_metadata.cc_host)[0]
    cluster            = var.cluster.name
    facetsclustername  = var.cluster.name
    facetsclusterid    = var.cluster.id
  }
  alb_data = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata = {
      name = "alb"
    }
    spec = {
      tags = [for key, value in local.cloud_tags : { key = key, value = value }]
    }
  }
  ingress_class_data = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "IngressClass"
    metadata = {
      name = "alb"
      annotations = {
        "ingressclass.kubernetes.io/is-default-class" = "true"
      }
    }
    spec = {
      controller = "eks.amazonaws.com/alb"
      parameters = {
        apiGroup = "eks.amazonaws.com"
        kind     = "IngressClassParams"
        name     = "alb"
      }
    }
  }
  default_node_pool_data = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default-node-pool"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "managed-by" = "facets"
          }
        }
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "eks.amazonaws.com/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "eks.amazonaws.com/instance-cpu"
              operator = "In"
              values   = ["4", "8", "16"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = [var.inputs.network_details.attributes.availability_zones[0]]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64", "amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = lookup(local.default_node_pool, "instance_types", ["t3a.medium", "t3a.xlarge", "m5a.xlarge"])
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = lookup(local.default_node_pool, "capacity_type", ["on-demand", "spot"])
            }
          ]
        }
      }
      # Limits should ideally be derived from local.default_node_pool configuration
      limits = {
        cpu    = lookup(local.default_node_pool, "max_size_cpu", 1000)
        memory = "${lookup(local.default_node_pool, "max_size_memory", 1000)}Gi"
      }
      # Consider adding disruption configuration if needed
      disruption = {
        consolidateAfter    = "1m"
        consolidationPolicy = lookup(local.default_node_pool, "disruption_policy", "WhenEmptyOrUnderutilized")
      }
    }
  }
  dedicated_node_pool_data = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "dedicated-node-pool"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            managed-by       = "facets"
            facets-node-type = "facets-dedicated"
          }
        }
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }
          taints = [
            {
              key    = "facets.cloud/dedicated"
              value  = "true"
              effect = "NoSchedule"
            }
          ]
          requirements = [
            {
              key      = "eks.amazonaws.com/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "eks.amazonaws.com/instance-cpu"
              operator = "In"
              values   = ["4", "8", "16"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = [var.inputs.network_details.attributes.availability_zones[0]]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64", "amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = lookup(local.dedicated_node_pool, "instance_types", ["t3a.medium", "t3a.xlarge", "m5a.xlarge"])
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = lookup(local.dedicated_node_pool, "capacity_type", ["on-demand", "spot"])
            }
          ]
        }
      }
      limits = {
        cpu    = lookup(local.dedicated_node_pool, "max_size_cpu", 1000)
        memory = "${lookup(local.dedicated_node_pool, "max_size_memory", 1000)}Gi"
      }
      disruption = {
        consolidateAfter    = "1m"
        consolidationPolicy = lookup(local.dedicated_node_pool, "disruption_policy", "WhenEmptyOrUnderutilized")
      }
    }
  }
}
