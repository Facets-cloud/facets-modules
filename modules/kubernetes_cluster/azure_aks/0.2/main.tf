# Generate a unique name for the AKS cluster
module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 63
  resource_name   = var.instance_name
  resource_type   = "kubernetes_cluster"
  globally_unique = true
}

# Create the AKS cluster using the official Azure module
module "k8scluster" {
  source = "./k8scluster"

  # Required variables
  resource_group_name = var.inputs.network_details.attributes.resource_group_name
  location            = var.inputs.network_details.attributes.region

  # Basic cluster configuration
  cluster_name = local.name
  prefix       = ""

  # Kubernetes version
  kubernetes_version = var.instance.spec.cluster.kubernetes_version

  # SKU tier
  sku_tier = var.instance.spec.cluster.sku_tier

  # Network configuration
  network_plugin = "azure"
  network_policy = "calico"
  vnet_subnet = {
    id = var.inputs.network_details.attributes.private_subnet_ids[0]
  }
  net_profile_service_cidr   = "10.254.0.0/16"
  net_profile_dns_service_ip = "10.254.0.254"

  # Private cluster configuration
  private_cluster_enabled         = !var.instance.spec.cluster.cluster_endpoint_public_access
  api_server_authorized_ip_ranges = var.instance.spec.cluster.cluster_endpoint_public_access ? var.instance.spec.cluster.cluster_endpoint_public_access_cidrs : null

  # Node pool configuration
  agents_count              = var.instance.spec.node_pools.system_np.node_count
  agents_size               = var.instance.spec.node_pools.system_np.instance_type
  agents_max_pods           = var.instance.spec.node_pools.system_np.max_pods
  os_disk_size_gb           = var.instance.spec.node_pools.system_np.os_disk_size_gb
  agents_availability_zones = var.inputs.network_details.attributes.availability_zones
  agents_pool_name          = "system"

  # Auto-scaling configuration
  enable_auto_scaling = var.instance.spec.node_pools.system_np.enable_auto_scaling
  agents_min_count    = var.instance.spec.node_pools.system_np.enable_auto_scaling ? var.instance.spec.node_pools.system_np.node_count : null
  agents_max_count    = var.instance.spec.node_pools.system_np.enable_auto_scaling ? 10 : null

  # System node pool - mark it as system mode
  only_critical_addons_enabled = true

  # Auto-upgrade configuration
  automatic_channel_upgrade = var.instance.spec.auto_upgrade_settings.enable_auto_upgrade ? var.instance.spec.auto_upgrade_settings.automatic_channel_upgrade : null

  # Maintenance window configuration
  maintenance_window_auto_upgrade = var.instance.spec.auto_upgrade_settings.enable_auto_upgrade && !var.instance.spec.auto_upgrade_settings.maintenance_window.is_disabled ? {
    frequency = "Weekly"
    interval  = 1
    duration  = var.instance.spec.auto_upgrade_settings.maintenance_window.end_time - var.instance.spec.auto_upgrade_settings.maintenance_window.start_time
    day_of_week = lookup({
      "SUN" = "Sunday"
      "MON" = "Monday"
      "TUE" = "Tuesday"
      "WED" = "Wednesday"
      "THU" = "Thursday"
      "FRI" = "Friday"
      "SAT" = "Saturday"
    }, var.instance.spec.auto_upgrade_settings.maintenance_window.day_of_week, "Sunday")
    start_time = format("%02d:00", var.instance.spec.auto_upgrade_settings.maintenance_window.start_time)
    utc_offset = "+00:00"
  } : null

  # Node surge configuration for upgrades
  agents_pool_max_surge = var.instance.spec.auto_upgrade_settings.max_surge

  # Enable Azure Policy
  azure_policy_enabled = true

  # Enable workload identity and OIDC issuer
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  # Enable monitoring if log analytics workspace is provided
  log_analytics_workspace_enabled = var.inputs.network_details.attributes.log_analytics_workspace_id != null
  log_analytics_workspace = var.inputs.network_details.attributes.log_analytics_workspace_id != null ? {
    id   = var.inputs.network_details.attributes.log_analytics_workspace_id
    name = split("/", var.inputs.network_details.attributes.log_analytics_workspace_id)[8]
  } : null

  # Auto-scaler profile configuration
  auto_scaler_profile_enabled                          = var.instance.spec.node_pools.system_np.enable_auto_scaling
  auto_scaler_profile_balance_similar_node_groups      = false
  auto_scaler_profile_expander                         = "random"
  auto_scaler_profile_max_graceful_termination_sec     = "600"
  auto_scaler_profile_max_node_provisioning_time       = "15m"
  auto_scaler_profile_max_unready_nodes                = 3
  auto_scaler_profile_max_unready_percentage           = 45
  auto_scaler_profile_new_pod_scale_up_delay           = "10s"
  auto_scaler_profile_scale_down_delay_after_add       = "10m"
  auto_scaler_profile_scale_down_delay_after_delete    = "10s"
  auto_scaler_profile_scale_down_delay_after_failure   = "3m"
  auto_scaler_profile_scan_interval                    = "10s"
  auto_scaler_profile_scale_down_unneeded              = "10m"
  auto_scaler_profile_scale_down_unready               = "20m"
  auto_scaler_profile_scale_down_utilization_threshold = "0.5"
  auto_scaler_profile_empty_bulk_delete_max            = 10
  auto_scaler_profile_skip_nodes_with_local_storage    = true
  auto_scaler_profile_skip_nodes_with_system_pods      = true

  # Node labels for system node pool
  agents_labels = {
    "facets.cloud/node-type" = "system"
    "managed-by"             = "facets"
  }

  # Tags
  tags = merge(
    var.environment.cloud_tags,
    var.instance.spec.tags != null ? var.instance.spec.tags : {}
  )

  # Disable http application routing
  http_application_routing_enabled = false

  # Disable local accounts for better security
  local_account_disabled = true

  # Enable RBAC with Azure AD
  rbac_aad                    = true
  rbac_aad_azure_rbac_enabled = true
}

# Data source to get current client configuration for authentication
data "azurerm_client_config" "current" {}
