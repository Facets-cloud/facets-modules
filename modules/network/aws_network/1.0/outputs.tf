locals {
  output_attributes = {
    vpc_id                          = aws_vpc.main.id
    vpc_cidr_block                  = aws_vpc.main.cidr_block
    nat_gateway_ids                 = values(aws_nat_gateway.main)[*].id
    public_subnet_ids               = values(aws_subnet.public)[*].id
    availability_zones              = local.selected_azs
    private_subnet_ids              = values(aws_subnet.private)[*].id
    database_subnet_ids             = values(aws_subnet.database)[*].id
    database_subnet_group_name      = aws_db_subnet_group.database.name
    internet_gateway_id             = aws_internet_gateway.main.id
    vpc_endpoint_s3_id              = try(aws_vpc_endpoint.s3[0].id, null)
    vpc_endpoint_dynamodb_id        = try(aws_vpc_endpoint.dynamodb[0].id, null)
    vpc_endpoint_ecr_api_id         = try(aws_vpc_endpoint.ecr_api[0].id, null)
    vpc_endpoint_ecr_dkr_id         = try(aws_vpc_endpoint.ecr_dkr[0].id, null)
    vpc_endpoints_security_group_id = try(aws_security_group.vpc_endpoints[0].id, null)
  }
  output_interfaces = {
  }
}