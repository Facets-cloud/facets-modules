locals {
  output_attributes = {
    node_class_name       = local.node_class_name
    node_pool_name        = local.node_pool_name
    node_class_manifest   = local.node_class_manifest
    node_pool_manifest    = local.node_pool_manifest
    taints                = local.taints
    node_selector         = local.labels
    subnet_selector_terms = local.subnet_selector_terms
  }
  output_interfaces = {
  }
}
