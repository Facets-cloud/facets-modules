locals {
  # Generate cluster name
  name = module.name.name

  # Extract spec configurations
  metadata = lookup(var.instance, "metadata", {})
  spec     = lookup(var.instance, "spec", {})

  # Cluster configuration
  cluster_config = lookup(local.spec, "cluster", {})

  # Node pools configuration
  node_pools_config = lookup(local.spec, "node_pools", {})
  system_np_config  = lookup(local.node_pools_config, "system_np", {})

  # Auto-upgrade configuration
  auto_upgrade_config = lookup(local.spec, "auto_upgrade_settings", {})
  maintenance_window  = lookup(local.auto_upgrade_config, "maintenance_window", {})

  # Features configuration
  features_config = lookup(local.spec, "features", {})

  # Tags configuration
  tags_config = lookup(local.spec, "tags", {})

  # Computed values for the cluster
  kubernetes_version = lookup(local.cluster_config, "kubernetes_version", "1.31")
  sku_tier           = lookup(local.cluster_config, "sku_tier", "Free")

  # Node pool computed values
  node_count          = lookup(local.system_np_config, "node_count", 1)
  instance_type       = lookup(local.system_np_config, "instance_type", "Standard_D2_v4")
  max_pods            = lookup(local.system_np_config, "max_pods", 30)
  os_disk_size_gb     = lookup(local.system_np_config, "os_disk_size_gb", 50)
  enable_auto_scaling = lookup(local.system_np_config, "enable_auto_scaling", false)

  # Auto-upgrade computed values
  enable_auto_upgrade       = lookup(local.auto_upgrade_config, "enable_auto_upgrade", true)
  automatic_channel_upgrade = lookup(local.auto_upgrade_config, "automatic_channel_upgrade", "stable")
  max_surge                 = lookup(local.auto_upgrade_config, "max_surge", "1")

  # Maintenance window computed values
  maintenance_window_disabled = lookup(local.maintenance_window, "is_disabled", true)
  maintenance_day_of_week     = lookup(local.maintenance_window, "day_of_week", "SUN")
  maintenance_start_time      = lookup(local.maintenance_window, "start_time", 2)
  maintenance_end_time        = lookup(local.maintenance_window, "end_time", 6)

  # Network access computed values
  cluster_endpoint_public_access       = lookup(local.cluster_config, "cluster_endpoint_public_access", true)
  cluster_endpoint_public_access_cidrs = lookup(local.cluster_config, "cluster_endpoint_public_access_cidrs", ["0.0.0.0/0"])
}
