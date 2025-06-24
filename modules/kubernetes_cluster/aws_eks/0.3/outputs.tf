locals {
  output_interfaces = {

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
    taints          = []
    node_selector   = local.facets_dedicated_node_pool.labels
  }
}
