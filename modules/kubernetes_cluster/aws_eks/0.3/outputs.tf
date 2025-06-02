locals {
  output_interfaces = {

  }
  output_attributes = {
    k8s_details    = module.k8s_cluster.k8s_details
    legacy_outputs = module.k8s_cluster.legacy_outputs
    network = {
      vpc_id      = var.inputs.network_details.vpc_id
      k8s_subnets = var.inputs.network_details.k8s_subnets
    }
  }
}
