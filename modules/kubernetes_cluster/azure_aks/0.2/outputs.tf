locals {
  output_interfaces = {
    # Add any interface outputs if needed
  }
  output_attributes = module.k8s_cluster.k8s_details
}

output "default_node_pool" {
  value = {
    node_class_name = local.facets_default_node_pool.node_class_name
    node_pool_name  = local.facets_default_node_pool.name
    taints          = []
    node_selector   = local.facets_default_node_pool.labels
  }
}

output "dedicated_node_pool" {
  value = {
    node_class_name = local.facets_dedicated_node_pool.node_class_name
    node_pool_name  = local.facets_dedicated_node_pool.name
    taints = [
      {
        key    = "facets.cloud/dedicated"
        value  = "true"
        effect = "NoSchedule"
      }
    ]
    node_selector = local.facets_dedicated_node_pool.labels
  }
}

output "cluster_details" {
  description = "AKS cluster details"
  value = {
    cluster_name        = module.k8s_cluster.k8s_details.cluster.name
    cluster_id          = module.k8s_cluster.k8s_details.cluster.id
    cluster_version     = module.k8s_cluster.k8s_details.cluster.version
    resource_group      = module.k8s_cluster.k8s_details.cluster.resource_group
    location            = module.k8s_cluster.k8s_details.cluster.location
    oidc_issuer_url     = module.k8s_cluster.k8s_details.cluster.oidc_issuer_url
    node_resource_group = module.k8s_cluster.k8s_details.node_group.node_resource_group
  }
}

output "auth_details" {
  description = "Authentication details for the cluster"
  value = {
    host                   = module.k8s_cluster.k8s_details.cluster.auth.host
    cluster_ca_certificate = module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate
    token                  = module.k8s_cluster.k8s_details.cluster.auth.token
  }
  sensitive = true
}

output "storage_details" {
  description = "Storage account details"
  value = {
    storage_account_name           = module.k8s_cluster.k8s_details.storage_account.name
    storage_account_resource_group = module.k8s_cluster.k8s_details.storage_account.resource_group_name
    primary_blob_endpoint          = module.k8s_cluster.k8s_details.storage_account.primary_blob_endpoint
  }
}

# Legacy outputs for backward compatibility
output "legacy_outputs" {
  value = module.k8s_cluster.legacy_outputs
}