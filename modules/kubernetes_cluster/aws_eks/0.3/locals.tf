locals {
  name                                   = module.name.name
  spec                                   = lookup(var.instance, "spec", {})
  cluster                                = lookup(local.spec, "cluster", {})
  node_pools                             = lookup(local.spec, "node_pools", {})
  default_node_pool                      = lookup(local.node_pools, "default", {})
  dedicated_node_pool                    = lookup(local.node_pools, "dedicated", {})
  cluster_endpoint_public_access         = lookup(local.cluster, "cluster_endpoint_public_access", true)
  cluster_endpoint_private_access        = lookup(local.cluster, "cluster_endpoint_private_access", true)
  cluster_endpoint_public_access_cidrs   = lookup(local.cluster, "cluster_endpoint_public_access_cidrs", ["0.0.0.0/0"])
  enable_cluster_encryption              = lookup(local.cluster, "enable_cluster_encryption", true)
  kubernetes_version                     = lookup(local.cluster, "kubernetes_version", "1.31")
  default_reclaim_policy                 = lookup(local.cluster, "default_reclaim_policy", "Delete")
  cluster_enabled_log_types              = lookup(local.cluster, "cluster_enabled_log_types", [])
  cluster_endpoint_private_access_cidrs  = lookup(local.cluster, "cluster_endpoint_private_access_cidrs", [])
  cloudwatch_log_group_retention_in_days = lookup(local.cluster, "cloudwatch_log_group_retention_in_days", 90)
  cluster_service_ipv4_cidr              = lookup(local.cluster, "cluster_service_ipv4_cidr", null)
  cluster_addons = {
    snapshot-controller = {
      enabled           = true
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v8.0.0-eksbuild.1"
    }
  }
  cloud_tags = {
    facetscontrolplane = split(".", var.cc_metadata.cc_host)[0]
    cluster            = var.cluster.name
    facetsclustername  = var.cluster.name
    facetsclusterid    = var.cluster.id
  }
  addons = {
    for name, attributes in local.cluster_addons : name => {
      addon_version            = lookup(attributes, "addon_version", null)
      configuration_values     = lookup(attributes, "configuration_values", null) != null ? lookup(attributes, "configuration_values", null) : null
      resolve_conflicts        = lookup(attributes, "resolve_conflicts", null)
      tags                     = merge(lookup(attributes, "tags", {}), local.cloud_tags)
      preserve                 = lookup(attributes, "preserve", false)
      service_account_role_arn = lookup(attributes, "service_account_role_arn", null)
    }
    if lookup(attributes, "enabled", true)
  }
  cluster_compute_config = {
    enabled    = true
    node_pools = ["system", "general-purpose"]
  }
  cluster_security_group_additional_rules = { for idx, cidr in local.cluster_endpoint_private_access_cidrs :
    "ingress_private_cidr_${idx}" => {
      description = "Allow private CIDR ${cidr} access to cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [cidr]
    }
  }
  tags = merge(var.environment.cloud_tags, lookup(local.spec, "tags", {}))
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
        kind = "IngressClassParams"
        name = "alb"
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
              values   = [var.inputs.network_details.attributes.legacy_outputs.vpc_details.azs[0]]
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
              effect = "NoSchedule" # Changed from "NO_SCHEDULE" to "NoSchedule"
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
              values   = [var.inputs.network_details.attributes.legacy_outputs.vpc_details.azs[0]]
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
      # Limits should ideally be derived from local.default_node_pool configuration
      limits = {
        cpu    = lookup(local.dedicated_node_pool, "max_size_cpu", 1000)
        memory = "${lookup(local.dedicated_node_pool, "max_size_memory", 1000)}Gi"
      }
      # Consider adding disruption configuration if needed
      disruption = {
        consolidateAfter    = "1m"
        consolidationPolicy = lookup(local.dedicated_node_pool, "disruption_policy", "WhenEmptyOrUnderutilized")
      }
    }
  }
}
