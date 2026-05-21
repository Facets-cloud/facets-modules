locals {
  output_interfaces = {}
  output_attributes = {
    topology_spread_key = "facets-cloud-fleet-${var.instance_name}"
    taints              = local.taints
    node_selector       = local.labels
  }
}