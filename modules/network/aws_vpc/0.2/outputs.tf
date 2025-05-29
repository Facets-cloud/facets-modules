locals {
  output_attributes = {
    vpc_id              = aws_vpc.main.id
    vpc_cidr            = aws_vpc.main.cidr_block
    azs                 = var.instance.spec.availability_zones
    k8s_nodes_subnets   = lookup(var.instance.spec, "k8s_nodes_subnets", [])
    k8s_cluster_subnets = lookup(var.instance.spec, "k8s_cluster_subnets", [])
    k8s_subnets         = length(aws_subnet.private[*].id) > 0 ? slice(aws_subnet.private[*].id, 0, 2) : []
    # private_subnet_ids  = values(aws_subnet.private)[*].id
    # public_subnet_ids   = values(aws_subnet.public)[*].id
    # nat_gateway_ids = values(aws_nat_gateway.main)[*].id
    # internet_gateway_id             = aws_internet_gateway.main.id
    # vpc_endpoint_s3_id              = try(aws_vpc_endpoint.s3[0].id, null)
    # vpc_endpoint_dynamodb_id        = try(aws_vpc_endpoint.dynamodb[0].id, null)
    # vpc_endpoint_ecr_api_id         = try(aws_vpc_endpoint.ecr_api[0].id, null)
    # vpc_endpoint_ecr_dkr_id         = try(aws_vpc_endpoint.ecr_dkr[0].id, null)
    # vpc_endpoints_security_group_id = try(aws_security_group.vpc_endpoints[0].id, null)
  }
  output_interfaces = {
  }
}