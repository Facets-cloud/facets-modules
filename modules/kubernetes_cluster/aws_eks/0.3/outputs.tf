locals {
  output_interfaces = {

  }
  output_attributes = merge(
    module.k8s_cluster.k8s_details,
    {
      network_details = var.inputs.network_details.attributes
    }
  )
}
