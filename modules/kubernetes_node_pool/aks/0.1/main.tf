locals {
  aks_advanced              = lookup(lookup(lookup(var.instance, "advanced", {}), "aks", {}), "node_pool", {})
  aks_upgrade_settings      = lookup(local.aks_advanced, "upgrade_settings", {})
  aks_kubelet_config        = lookup(local.aks_advanced, "kubelet_config", {})
  aks_linux_os_config       = lookup(local.aks_advanced, "linux_os_config", {})
  aks_sysctl_config         = lookup(local.aks_linux_os_config, "sysctl_config", {})
  metadata                  = lookup(var.instance, "metadata", {})
  priority                  = lookup(local.aks_advanced, "priority", "Regular")
  user_defined_tags         = lookup(local.aks_advanced, "tags", {})
  facets_defined_cloud_tags = lookup(var.environment, "cloud_tags", {})
  tags                      = merge(local.user_defined_tags, local.facets_defined_cloud_tags)

  name = lookup(local.metadata, "name", var.instance_name)

  #  zones  = coalescelist(values((lookup(var.instance.spec, "zones", {}))), var.environment.azs)
  #  zones =  lookup(var.instance.spec, "zones", var.environment.azs)
  taints         = [for taint in var.instance.spec.taints : "${taint.key}=${taint.value}:${taint.effect}"]
  spot_max_price = lookup(local.aks_advanced, "spot_max_price", null)
  // os type when windows
  os_type = lookup(local.aks_advanced, "os_type", "Linux")
}

resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
  provider              = "azurerm3-105-0"
  name                  = local.os_type == "Windows" && length(local.name) >= 6 ? "windos" : local.name //replacing the name to windos if os is window to
  kubernetes_cluster_id = var.inputs.kubernetes_details.attributes.legacy_outputs.azure_cloud.kubernetes_cluster_id
  vm_size               = var.instance.spec.instance_type
  os_disk_size_gb       = trim(var.instance.spec.disk_size, "G")
  os_type               = local.os_type
  os_disk_type          = lookup(local.aks_advanced, "os_disk_type", "Managed")
  #  os_sku                = local.os_type == "Linux" ? lookup(local.aks_advanced, "os_sku", "Ubuntu") : null
  #  os_sku                = lookup(local.aks_advanced, "os_sku", "Ubuntu")

  enable_auto_scaling = lookup(local.aks_advanced, "enable_auto_scaling", true)
  max_count           = var.instance.spec.max_node_count
  min_count           = var.instance.spec.min_node_count
  node_count          = lookup(local.aks_advanced, "node_count", var.instance.spec.min_node_count)
  node_taints         = local.taints
  node_labels         = lookup(var.instance.spec, "labels", {})
  max_pods            = lookup(local.aks_advanced, "max_pods", null)

  //referred as on_demand under spec
  priority = lookup(local.aks_advanced, "priority", "Regular")

  enable_host_encryption = lookup(local.aks_advanced, "enable_host_encryption", false)
  enable_node_public_ip  = lookup(local.aks_advanced, "enable_node_public_ip", false)

  mode = lookup(local.aks_advanced, "mode", "User")
  #  zones                = local.zones
  orchestrator_version = lookup(local.aks_advanced, "orchestrator_version", null)
  #  scale_down_mode      = lookup(local.aks_advanced, "scale_down_mode", "Delete")
  vnet_subnet_id  = lookup(local.aks_advanced, "vnet_subnet_id", var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnets[0])
  eviction_policy = local.priority == "Spot" ? lookup(local.aks_advanced, "eviction_policy", "Delete") : null
  #  workload_runtime     = lookup(local.aks_advanced, "workload_runtime", null)

  tags           = local.tags
  spot_max_price = local.priority == "Spot" ? lookup(local.aks_advanced, "spot_max_price", "-1") : local.spot_max_price
  zones          = length(compact(var.cluster.azs)) == 0 ? null : [var.cluster.azs[0]]


  #  kubelet_config {
  #    allowed_unsafe_sysctls    = lookup(local.aks_kubelet_config, "allowed_unsafe_sysctls", null)
  #    container_log_max_line    = lookup(local.aks_kubelet_config, "container_log_max_line", 2)
  #    container_log_max_size_mb = lookup(local.aks_kubelet_config, "container_log_max_size_mb", 2)
  #    cpu_cfs_quota_enabled     = lookup(local.aks_kubelet_config, "cpu_cfs_quota_enabled", false)
  #    cpu_cfs_quota_period      = lookup(local.aks_kubelet_config, "cpu_cfs_quota_period", "30ms")
  #    cpu_manager_policy        = lookup(local.aks_kubelet_config, "cpu_manager_policy", "none")
  #    image_gc_high_threshold   = lookup(local.aks_kubelet_config, "image_gc_high_threshold", 70)
  #    image_gc_low_threshold    = lookup(local.aks_kubelet_config, "image_gc_low_threshold", 0)
  #    pod_max_pid               = lookup(local.aks_kubelet_config, "pod_max_pid", 32600)
  #    topology_manager_policy   = lookup(local.aks_kubelet_config, "topology_manager_policy", "none")
  #  }


  #  linux_os_config {
  #    swap_file_size_mb             = lookup(local.aks_linux_os_config, "swap_file_size_mb", null)
  #    transparent_huge_page_enabled = lookup(local.aks_linux_os_config, "transparent_huge_page_enabled", null)
  #    transparent_huge_page_defrag  = lookup(local.aks_linux_os_config, "transparent_huge_page_defrag", null)
  dynamic "linux_os_config" {
    for_each = length(local.aks_linux_os_config) > 0 ? [local.aks_linux_os_config] : []
    content {
      swap_file_size_mb             = lookup(linux_os_config.value, "swap_file_size_mb", null)
      transparent_huge_page_enabled = lookup(linux_os_config.value, "transparent_huge_page_enabled", null)
      transparent_huge_page_defrag  = lookup(linux_os_config.value, "transparent_huge_page_defrag", null)

      dynamic "sysctl_config" {
        for_each = length(local.aks_sysctl_config) > 0 ? [local.aks_sysctl_config] : []
        content {
          fs_aio_max_nr                      = lookup(sysctl_config.value, "fs_aio_max_nr", null)
          fs_file_max                        = lookup(sysctl_config.value, "fs_file_max", null)
          fs_inotify_max_user_watches        = lookup(sysctl_config.value, "fs_inotify_max_user_watches", null)
          fs_nr_open                         = lookup(sysctl_config.value, "fs_nr_open", null)
          kernel_threads_max                 = lookup(sysctl_config.value, "kernel_threads_max", null)
          net_core_netdev_max_backlog        = lookup(sysctl_config.value, "net_core_netdev_max_backlog", null)
          net_core_optmem_max                = lookup(sysctl_config.value, "net_core_optmem_max", null)
          net_core_rmem_default              = lookup(sysctl_config.value, "net_core_rmem_default", null)
          net_core_rmem_max                  = lookup(sysctl_config.value, "net_core_rmem_max", null)
          net_core_somaxconn                 = lookup(sysctl_config.value, "net_core_somaxconn", null)
          net_core_wmem_default              = lookup(sysctl_config.value, "net_core_wmem_default", null)
          net_core_wmem_max                  = lookup(sysctl_config.value, "net_core_wmem_max", null)
          net_ipv4_ip_local_port_range_max   = lookup(sysctl_config.value, "net_ipv4_ip_local_port_range_max", null)
          net_ipv4_ip_local_port_range_min   = lookup(sysctl_config.value, "net_ipv4_ip_local_port_range_min", null)
          net_ipv4_neigh_default_gc_thresh1  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh1", null)
          net_ipv4_neigh_default_gc_thresh2  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh2", null)
          net_ipv4_neigh_default_gc_thresh3  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh3", null)
          net_ipv4_tcp_fin_timeout           = lookup(sysctl_config.value, "net_ipv4_tcp_fin_timeout", null)
          net_ipv4_tcp_keepalive_intvl       = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_intvl", null)
          net_ipv4_tcp_keepalive_probes      = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_probes", null)
          net_ipv4_tcp_keepalive_time        = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_time", null)
          net_ipv4_tcp_max_syn_backlog       = lookup(sysctl_config.value, "net_ipv4_tcp_max_syn_backlog", null)
          net_ipv4_tcp_max_tw_buckets        = lookup(sysctl_config.value, "net_ipv4_tcp_max_tw_buckets", null)
          net_ipv4_tcp_tw_reuse              = lookup(sysctl_config.value, "net_ipv4_tcp_tw_reuse", null)
          net_netfilter_nf_conntrack_buckets = lookup(sysctl_config.value, "net_netfilter_nf_conntrack_buckets", null)
          net_netfilter_nf_conntrack_max     = lookup(sysctl_config.value, "net_netfilter_nf_conntrack_max", null)
          vm_max_map_count                   = lookup(sysctl_config.value, "vm_max_map_count", null)
          vm_swappiness                      = lookup(sysctl_config.value, "vm_swappiness", null)
          vm_vfs_cache_pressure              = lookup(sysctl_config.value, "vm_vfs_cache_pressure", null)
        }
      }

    }

  }

  // max_surge NA if priority == spot
  # upgrade_settings {
  #   //max_surge = lookup(local.aks_upgrade_settings, "max_surge", 1)
  #   max_surge = local.priority == "Regular" ? lookup(local.aks_upgrade_settings, "max_surge", 1) : ""
  # }
  dynamic "upgrade_settings" {
    for_each = local.priority == "Regular" ? [1] : []
    content {
      max_surge = lookup(local.aks_upgrade_settings, "max_surge", lookup(lookup(var.inputs.kubernetes_details.attributes.legacy_outputs, "cluster_auto_upgrade", {}), "max_surge", "10%")
      )
    }
  }

  timeouts {
    create = "60m"
    delete = "2h"
  }
  lifecycle {
    ignore_changes = ["node_count", "kubernetes_cluster_id", "zones", "orchestrator_version", "name", "ultra_ssd_enabled", "scale_down_mode", "custom_ca_trust_enabled", "fips_enabled", "kubelet_disk_type", "os_sku", "windows_profile"]
  }
}

output "main_output" {
  value = {
    #zones = local.zones
  }
}



