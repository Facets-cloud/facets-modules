locals {
  name                      = module.name.name
  spec                      = lookup(var.instance, "spec", {})
  cluster                   = lookup(local.spec, "cluster", {})
  auto_upgrade_settings     = lookup(local.spec, "auto_upgrade_settings", {})
  
  # Cluster configuration
  kubernetes_version                     = lookup(local.cluster, "kubernetes_version", "1.31")
  automatic_channel_upgrade              = lookup(local.auto_upgrade_settings, "automatic_channel_upgrade", "stable")
  enable_auto_upgrade                    = lookup(local.auto_upgrade_settings, "enable_auto_upgrade", true)
  max_surge                              = lookup(local.auto_upgrade_settings, "max_surge", "1")
  
  # Access configuration
  cluster_endpoint_public_access         = lookup(local.cluster, "cluster_endpoint_public_access", true)
  cluster_endpoint_private_access        = lookup(local.cluster, "cluster_endpoint_private_access", false)
  cluster_endpoint_public_access_cidrs   = lookup(local.cluster, "cluster_endpoint_public_access_cidrs", ["0.0.0.0/0"])
  cluster_endpoint_private_access_cidrs  = lookup(local.cluster, "cluster_endpoint_private_access_cidrs", [])
  
  # Node pool configuration
  node_pools                = lookup(local.spec, "node_pools", {})
  system_np                 = lookup(local.node_pools, "system_np", {})
  default_np                = lookup(local.node_pools, "default", {})
  facets_dedicated_np       = lookup(local.node_pools, "facets_dedicated", {})
  enable_default_nodepool   = lookup(local.system_np, "enabled", true)
  
  # Maintenance window configuration
  maintenance_window        = lookup(local.auto_upgrade_settings, "maintenance_window", {})
  maintenance_window_config = {
    is_disabled   = lookup(local.maintenance_window, "is_disabled", true)
    day_of_week   = lookup(local.maintenance_window, "day_of_week", "SUN")
    start_time    = lookup(local.maintenance_window, "start_time", 2)
    end_time      = lookup(local.maintenance_window, "end_time", 6)
  }
  
  # Day abbreviation mapping
  day_abbreviation_to_full_name = {
    "SUN" = "Sunday"
    "MON" = "Monday"
    "TUE" = "Tuesday"
    "WED" = "Wednesday"
    "THU" = "Thursday"
    "FRI" = "Friday"
    "SAT" = "Saturday"
  }
  
  # Calculate maintenance window hours
  hours = range(0, 24)
  maintenance_window_hours = (
    local.maintenance_window_config.start_time <= local.maintenance_window_config.end_time
    ? slice(local.hours, local.maintenance_window_config.start_time, local.maintenance_window_config.end_time + 1)
    : concat(
      slice(local.hours, local.maintenance_window_config.start_time, 24),
      slice(local.hours, 0, local.maintenance_window_config.end_time + 1)
    )
  )
  
  # Storage and networking
  default_reclaim_policy    = lookup(local.cluster, "default_reclaim_policy", "Delete")
  cluster_enabled_log_types = lookup(local.cluster, "cluster_enabled_log_types", [])
  sku_tier                  = lookup(local.cluster, "sku_tier", "Free")
  
  # Resource naming
  aks_name = "${substr(var.cluster.name, 0, 45 - 11)}-${var.cluster.clusterCode}"
  node_resource_group = "MC_${substr(var.cluster.name, 0, 53)}_${var.cluster.clusterCode}_node_res_grp"
  
  # Cloud tags
  cloud_tags = {
    facetscontrolplane = split(".", var.cc_metadata.cc_host)[0]
    cluster            = var.cluster.name
    facetsclustername  = var.cluster.name
    facetsclusterid    = var.cluster.id
  }
  
  tags = merge(var.environment.cloud_tags, lookup(local.spec, "tags", {}), local.cloud_tags)
}