locals {
  output_attributes = {
    node_class_name = local.node_class_name
    node_pool_name  = local.node_pool_name
    taints          = local.taints
    node_selector   = local.labels
  }
  output_interfaces = {
  }
}
