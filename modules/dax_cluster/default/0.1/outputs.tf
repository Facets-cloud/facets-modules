locals {
  output_attributes = {
    configuration_endpoint = aws_dax_cluster.dax_cluster.configuration_endpoint
    cluster_address        = aws_dax_cluster.dax_cluster.cluster_address
    arn                    = aws_dax_cluster.dax_cluster.arn
    port                   = aws_dax_cluster.dax_cluster.port
    node = {
      id                = aws_dax_cluster.dax_cluster.nodes.0.id
      address           = aws_dax_cluster.dax_cluster.nodes.0.address
      port              = aws_dax_cluster.dax_cluster.nodes.0.port
      availability_zone = aws_dax_cluster.dax_cluster.nodes.0.availability_zone
    }
  }
  output_interfaces = {}
}