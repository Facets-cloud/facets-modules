locals {
  output_interfaces = {}
  output_attributes = {
    k8s_details = module.k8s_cluster.k8s_details
    legacy_outputs = module.k8s_cluster.k8s_details.legacy_outputs
  }
}
