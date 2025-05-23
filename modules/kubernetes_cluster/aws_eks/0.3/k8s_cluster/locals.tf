locals {
  name                                   = module.name.name
  spec                                   = lookup(var.instance, "spec", {})
  cluster                                = lookup(local.spec, "cluster", {})
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
}
