locals {
  gke_advanced                  = lookup(lookup(var.instance, "advanced", {}), "gke", {})
  gke_advanced_management       = lookup(local.gke_advanced, "management", {})
  gke_advanced_upgrade_settings = lookup(local.gke_advanced, "upgrade_settings", {})
  gke_advanced_node_config      = lookup(local.gke_advanced, "node_config", {})
  gke_advanced_network_config   = lookup(local.gke_advanced, "network_config", {})
  #  pod_ip_range_name = lookup(local.gke_advanced_network_config, "pod_ipv4_cidr_block", null) == null ? var.inputs.network_details.attributes.legacy_outputs.vpc_details.secondary_ip_range_names.pod_cidr_range : "${var.cluster.stackName}-${var.cluster.name}-${var.instance_name}-pods"
  pod_ip_range_name = var.inputs.network_details.attributes.legacy_outputs.vpc_details.secondary_ip_range_names.pod_cidr_range
  spec              = lookup(var.instance, "spec", {})
  labels            = lookup(local.spec, "labels", {})
  spot              = lookup(local.gke_advanced_node_config, "spot", false)
  iam_roles         = lookup(lookup(local.spec, "iam", {}), "roles", {})
}

module "sa-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 30
  globally_unique = false
  resource_name   = var.instance_name
  resource_type   = ""
  is_k8s          = false
  prefix          = "sa"
}

resource "google_service_account" "sa" {
  count = length(local.iam_roles) > 0 ? 1 : 0

  account_id   = module.sa-name.name
  display_name = "Terraform-managed service account that Node Pool can use"
}

resource "google_project_iam_member" "np-account-iam" {
  for_each = local.iam_roles

  project = google_service_account.sa[0].project
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.sa[0].email}"
}

resource "google_container_node_pool" "node_pool" {
  project     = var.cluster.project
  provider    = "google-beta"
  name_prefix = "${var.instance_name}-"
  cluster     = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_name
  location    = lookup(var.inputs.network_details.attributes.legacy_outputs.vpc_details, "region", lookup(var.cluster, "region", null))

  autoscaling {
    min_node_count = lookup(local.spec, "min_node_count", null)
    max_node_count = lookup(local.spec, "max_node_count", null)
  }

  management {
    auto_repair  = lookup(local.gke_advanced_management, "auto_repair", true)
    auto_upgrade = lookup(local.gke_advanced_management, "auto_upgrade", false)
  }

  initial_node_count = lookup(local.spec, "min_node_count", null)
  max_pods_per_node  = lookup(local.gke_advanced, "max_pods_per_node", null)
  node_locations     = lookup(local.gke_advanced, "node_locations", null)

  upgrade_settings {
    max_surge       = lookup(local.gke_advanced_upgrade_settings, "max_surge", 1)
    max_unavailable = lookup(local.gke_advanced_upgrade_settings, "max_unavailable", 0)
  }
  version = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.kubernetes_version

  node_config {
    machine_type = lookup(local.spec, "instance_type", null)
    image_type   = "COS_CONTAINERD"
    disk_size_gb = lookup(local.spec, "disk_size", null)
    dynamic "taint" {
      for_each = lookup(local.spec, "taints", [])
      content {
        key    = taint.value["key"]
        value  = taint.value["value"]
        effect = taint.value["effect"]
      }
    }
    labels          = local.labels
    resource_labels = merge(local.labels, lookup(lookup(var.instance, "metadata", {}), "labels", {}))
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = length(local.iam_roles) > 0 ? google_service_account.sa[0].email : var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.node_pool_service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    disk_type = lookup(local.spec, "disk_type", lookup(local.gke_advanced_node_config, "disk_type", null))
    metadata = {
      disable-legacy-endpoints = "true"
    }
    preemptible = lookup(local.gke_advanced_node_config, "preemptible", null)
    tags = [
      "gke-${var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_name}"
    ]
    spot = local.spot

    dynamic "sandbox_config" {
      for_each = tobool(lookup(local.spec, "sandbox_enabled", false)) ? ["gvisor"] : []
      content {
        sandbox_type = sandbox_config.value
      }
    }

    dynamic "guest_accelerator" {
      for_each = length(lookup(local.gke_advanced_node_config, "guest_accelerator", {})) > 0 ? local.gke_advanced_node_config["guest_accelerator"] : {}
      content {
        type  = guest_accelerator.value["type"]
        count = guest_accelerator.value["count"]
      }
    }

    shielded_instance_config {
      enable_secure_boot          = lookup(lookup(local.gke_advanced_node_config, "shielded_instance_config", {}), "enable_secure_boot", false)
      enable_integrity_monitoring = lookup(lookup(local.gke_advanced_node_config, "shielded_instance_config", {}), "enable_integrity_monitoring", true)
    }

    kubelet_config {
      cpu_manager_policy = lookup(local.gke_advanced_node_config, "cpu_manager_policy", "static")
      cpu_cfs_quota      = lookup(local.gke_advanced_node_config, "cpu_cfs_quota", false)
      pod_pids_limit     = lookup(local.gke_advanced_node_config, "pod_pids_limit", 0)
    }
  }

  network_config {
    ## ID of the secondary range for pod IPs in string
    pod_range            = local.pod_ip_range_name
    enable_private_nodes = !lookup(local.spec, "is_public", false)
  }

  lifecycle {
    ignore_changes        = [version, node_config.0.image_type, initial_node_count, network_config.0.enable_private_nodes, node_config.0.resource_labels]
    create_before_destroy = true
    prevent_destroy       = true
  }
}
