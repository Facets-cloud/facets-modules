locals {
  output_attributes = {
    node_class_name = local.node_class_name
    node_pool_name  = local.node_pool_name
    manifests       = local.all_manifests
  }
  output_interfaces = {
  }
}