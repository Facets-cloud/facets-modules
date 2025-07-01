module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "kubernetes_cluster"
  globally_unique = true
}

data "azurerm_kubernetes_service_versions" "current" {
  location        = var.vpc_details.region
  version_prefix  = local.kubernetes_version
  include_preview = false
}

# SSH key for Linux nodes
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh.private_key_pem
  filename = "./private_ssh_key"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                              = local.aks_name
  location                          = var.region
  resource_group_name               = var.resource_group_name
  node_resource_group               = local.node_resource_group
  dns_prefix                        = local.aks_name
  kubernetes_version                = local.kubernetes_version
  automatic_channel_upgrade         = local.enable_auto_upgrade ? local.automatic_channel_upgrade : null
  role_based_access_control_enabled = true
  sku_tier                          = local.sku_tier
  
  identity {
    type = "SystemAssigned"
  }
  
  default_node_pool {
    name                         = "defaultnp"
    node_count                   = lookup(local.system_np, "node_count", 1)
    vm_size                      = lookup(local.system_np, "instance_type", "Standard_D2_v4")
    type                         = "VirtualMachineScaleSets"
    max_pods                     = lookup(local.system_np, "max_pods", 30)
    os_disk_size_gb              = lookup(local.system_np, "os_disk_size_gb", 50)
    enable_auto_scaling          = lookup(local.system_np, "enable_auto_scaling", false)
    only_critical_addons_enabled = lookup(local.system_np, "enable_critical_addons", true)
    enable_node_public_ip        = lookup(local.system_np, "enable_node_public_ip", false)
    vnet_subnet_id               = var.k8s_subnets[0]
    zones                        = length(compact(var.azs)) == 0 ? null : [var.azs[0]]
    orchestrator_version         = data.azurerm_kubernetes_service_versions.current.latest_version
    temporary_name_for_rotation  = "tmpdefaultnp"
    
    dynamic "upgrade_settings" {
      for_each = local.enable_auto_upgrade ? [1] : []
      content {
        max_surge = local.max_surge
      }
    }
  }
  
  network_profile {
    network_plugin = "azure"
  }
  
  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = replace(tls_private_key.ssh.public_key_openssh, "\n", "")
    }
  }
  
  dynamic "maintenance_window" {
    for_each = local.maintenance_window_config.is_disabled == false ? [1] : []
    content {
      allowed {
        day   = lookup(local.day_abbreviation_to_full_name, local.maintenance_window_config.day_of_week, "Sunday")
        hours = local.maintenance_window_hours
      }
    }
  }
  
  tags = local.tags
  
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      sku_tier,
      role_based_access_control_enabled,
      name,
      dns_prefix,
      node_resource_group,
      public_network_access_enabled,
      image_cleaner_enabled,
      image_cleaner_interval_hours,
      private_cluster_public_fqdn_enabled,
      run_command_enabled,
      workload_identity_enabled,
      network_profile,
      auto_scaler_profile,
      identity,
      default_node_pool
    ]
  }
}

# Generate unique suffix for node pools
locals {
  np_unique_seed     = "${local.default_np}-${lookup(local.default_np, "root_disk_volume", 100)}"
  np_unique_seed_md5 = md5(local.np_unique_seed)
  np_suffix          = substr(local.np_unique_seed_md5, 0, 3)
}

# On-demand node pool
resource "azurerm_kubernetes_cluster_node_pool" "ondemand_node_pool" {
  count                 = lookup(local.default_np, "node_lifecycle_type", "SPOT") == "ON_DEMAND" && local.enable_default_nodepool ? 1 : 0
  name                  = "ondemand${local.np_suffix}"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = local.default_np.instance_type
  node_count            = 1
  enable_auto_scaling   = true
  mode                  = "System"
  max_pods              = 50
  min_count             = 1
  max_count             = lookup(local.default_np, "max_nodes", 200)
  os_disk_size_gb       = lookup(local.default_np, "root_disk_volume", 100)
  os_disk_type          = lookup(local.default_np, "azure_disk_type", "Managed") == "Ephemeral" ? "Ephemeral" : null
  enable_node_public_ip = false
  vnet_subnet_id        = var.private_subnets[2]
  zones                 = length(compact(var.azs)) == 0 ? null : [var.azs[0]]
  tags                  = local.tags
  
  dynamic "upgrade_settings" {
    for_each = local.enable_auto_upgrade ? [1] : []
    content {
      max_surge = local.max_surge
    }
  }
  
  lifecycle {
    ignore_changes  = [node_count, zones, orchestrator_version, name]
    prevent_destroy = true
  }
}

# Spot node pool
resource "azurerm_kubernetes_cluster_node_pool" "spot_node_pool" {
  count                 = lookup(local.default_np, "node_lifecycle_type", "SPOT") == "SPOT" && local.enable_default_nodepool ? 1 : 0
  name                  = "spot${local.np_suffix}"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = local.default_np.instance_type
  node_count            = 1
  priority              = "Spot"
  spot_max_price        = -1
  eviction_policy       = "Delete"
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = lookup(local.default_np, "max_nodes", 200)
  mode                  = "User"
  max_pods              = 50
  os_disk_size_gb       = lookup(local.default_np, "root_disk_volume", 100)
  os_disk_type          = lookup(local.default_np, "azure_disk_type", "Managed") == "Ephemeral" ? "Ephemeral" : null
  enable_node_public_ip = false
  vnet_subnet_id        = var.private_subnets[0]
  zones                 = length(compact(var.azs)) == 0 ? null : [var.azs[0]]
  node_taints           = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  tags                  = local.tags
  
  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "ccLifecycle"                           = "spot"
  }
  
  lifecycle {
    ignore_changes  = [node_count, zones, orchestrator_version, name, ultra_ssd_enabled, scale_down_mode]
    prevent_destroy = true
  }
}

# Facets dedicated node pool
resource "azurerm_kubernetes_cluster_node_pool" "facets_dedicated_np" {
  count                 = lookup(local.facets_dedicated_np, "enable", "true") ? 1 : 0
  name                  = "facets"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = lookup(local.facets_dedicated_np, "instance_type", "standard_D4as_v5")
  node_count            = 1
  priority              = lookup(local.facets_dedicated_np, "node_lifecycle_type", "SPOT") == "SPOT" ? "Spot" : "Regular"
  spot_max_price        = lookup(local.facets_dedicated_np, "node_lifecycle_type", "SPOT") == "SPOT" ? -1 : null
  eviction_policy       = lookup(local.facets_dedicated_np, "node_lifecycle_type", "SPOT") == "SPOT" ? "Delete" : null
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = lookup(local.facets_dedicated_np, "max_nodes", 200)
  mode                  = "User"
  max_pods              = 50
  os_disk_size_gb       = lookup(local.facets_dedicated_np, "root_disk_volume", 100)
  enable_node_public_ip = false
  vnet_subnet_id        = var.private_subnets[1]
  zones                 = length(compact(var.azs)) == 0 ? null : [var.azs[0]]
  orchestrator_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  node_taints           = lookup(local.facets_dedicated_np, "node_lifecycle_type", "SPOT") == "SPOT" ? ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule", "facets.cloud/dedicated=true:NoSchedule"] : ["facets.cloud/dedicated=true:NoSchedule"]
  tags                  = local.tags
  
  node_labels = merge({
    facets-node-type = "facets-dedicated"
    }, lookup(local.facets_dedicated_np, "node_lifecycle_type", "SPOT") == "SPOT" ? {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    ccLifecycle                             = "spot"
  } : {})
  
  dynamic "upgrade_settings" {
    for_each = local.enable_auto_upgrade && var.settings.FACETS_DEDICATED_NODE_LIFECYCLE_TYPE != "SPOT" ? [1] : []
    content {
      max_surge = local.max_surge
    }
  }
  
  lifecycle {
    ignore_changes  = [node_count, zones, orchestrator_version, ultra_ssd_enabled]
    prevent_destroy = true
  }
}

# Storage account
data "http" "whatismyip" {
  url = "http://ipv4.icanhazip.com"
}

resource "azurerm_storage_account" "storageacct" {
  name                     = "${substr(replace(var.cluster.name, "-", ""), 0, 24 - 10)}${var.cluster.clusterCode}"
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"
  
  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["${chomp(data.http.whatismyip.body)}"]
    virtual_network_subnet_ids = concat(var.private_subnets, var.public_subnets)
  }
  
  blob_properties {
    last_access_time_enabled = lookup(local.spec, "storage_account_last_access_time_enabled", true)
  }
  
  tags = local.tags
  
  lifecycle {
    ignore_changes = [
      name,
      nfsv3_enabled,
      infrastructure_encryption_enabled,
      queue_encryption_key_type,
      table_encryption_key_type,
      cross_tenant_replication_enabled,
      default_to_oauth_authentication,
      public_network_access_enabled,
      sftp_enabled,
      shared_access_key_enabled,
      allow_nested_items_to_be_public
    ]
  }
}

# Role assignments
resource "azurerm_role_assignment" "cluster_identity_role_assignment" {
  scope                = var.resource_group_name
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}

# These providers need to be force replaced with empty object blocks to prevent Terraform from using default providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    null = {
      source = "hashicorp/null"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}

provider "kubernetes" {
  alias                  = "k8s"
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  alias = "k8s"
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
  }
}