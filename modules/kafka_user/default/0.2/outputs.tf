locals {
  output_attributes = {
    username = var.inputs.kafka_details.interfaces.cluster.username
    password = sensitive(var.inputs.kafka_details.interfaces.cluster.password)
    secrets  = ["password"]
  }
  output_interfaces = {}
}
