locals {
  # VPC details based on whether we're creating new or using existing VPC
  vpc_details = local.create_new_vpc ? {
    vpc_id                         = module.vpc[0].vpc_id
    azs                            = local.actual_azs
    private_subnets                = slice(module.vpc[0].private_subnets, 0, 2)
    k8s_subnets                    = slice(module.vpc[0].private_subnets, 2, 8)
    public_subnets                 = module.vpc[0].public_subnets
    public_route_table_ids         = module.vpc[0].public_route_table_ids
    private_route_table_ids        = module.vpc[0].private_route_table_ids
    default_subnet_id              = length(module.vpc[0].private_subnets) > 0 ? module.vpc[0].private_subnets[0] : null
    default_security_group_id      = aws_security_group.allow_all_default.id
    default_private_route_table_id = length(module.vpc[0].private_route_table_ids) > 0 ? module.vpc[0].private_route_table_ids[0] : null
    private_route_table_ids_list   = join(",", module.vpc[0].private_route_table_ids)
    vpc_cidr                       = module.vpc[0].vpc_cidr_block
    private_subnet_objects = {
      id   = slice(module.vpc[0].private_subnets, 0, 2)
      cidr = slice(module.vpc[0].private_subnets_cidr_blocks, 0, 2)
    }
    az_subnets = length(module.vpc[0].private_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(module.vpc[0].private_subnets)) :
        module.vpc[0].private_subnets[j] if j % length(local.actual_azs) == i
      ]
    } : {}
    az_private_subnets = length(module.vpc[0].private_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(module.vpc[0].private_subnets)) :
        module.vpc[0].private_subnets[j] if j % length(local.actual_azs) == i
      ]
    } : {}
    az_public_subnets = length(module.vpc[0].public_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(module.vpc[0].public_subnets)) :
        module.vpc[0].public_subnets[j] if j % length(local.actual_azs) == i
      ]
    } : {}
    nat_gateway_ips            = module.vpc[0].nat_public_ips
    public_subnets_cidr_blocks = module.vpc[0].public_subnets_cidr_blocks
    nat_gateway_count          = length(module.vpc[0].nat_public_ips)
    az_public_subnets_cidrs = length(module.vpc[0].public_subnets_cidr_blocks) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(module.vpc[0].public_subnets_cidr_blocks)) :
        module.vpc[0].public_subnets_cidr_blocks[j] if j % length(local.actual_azs) == i
      ]
    } : {}
    az_private_subnets_cidrs = length(module.vpc[0].private_subnets_cidr_blocks) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(module.vpc[0].private_subnets_cidr_blocks)) :
        module.vpc[0].private_subnets_cidr_blocks[j] if j % length(local.actual_azs) == i
      ]
    } : {}
    } : {
    vpc_id                         = data.aws_vpc.existing[0].id
    azs                            = local.actual_azs
    private_subnets                = slice(aws_subnet.private_subnets[*].id, 0, 2)
    k8s_subnets                    = slice(aws_subnet.private_subnets[*].id, 2, 8)
    public_subnets                 = aws_subnet.public_subnets[*].id
    public_route_table_ids         = [aws_route_table.public[0].id]
    private_route_table_ids        = aws_route_table.private[*].id
    default_subnet_id              = length(aws_subnet.private_subnets) > 0 ? aws_subnet.private_subnets[0].id : null
    default_security_group_id      = aws_security_group.allow_all_default.id
    default_private_route_table_id = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : null
    private_route_table_ids_list   = join(",", aws_route_table.private[*].id)
    vpc_cidr                       = local.vpc_cidr
    private_subnet_objects = {
      id   = slice(aws_subnet.private_subnets[*].id, 0, 2)
      cidr = slice(aws_subnet.private_subnets[*].cidr_block, 0, 2)
    }
    az_subnets = length(aws_subnet.private_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(aws_subnet.private_subnets)) :
        aws_subnet.private_subnets[j].id if j % length(local.actual_azs) == i
      ]
    } : {}
    az_private_subnets = length(aws_subnet.private_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(aws_subnet.private_subnets)) :
        aws_subnet.private_subnets[j].id if j % length(local.actual_azs) == i
      ]
    } : {}
    az_public_subnets = length(aws_subnet.public_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(aws_subnet.public_subnets)) :
        aws_subnet.public_subnets[j].id if j % length(local.actual_azs) == i
      ]
    } : {}
    nat_gateway_ips            = aws_eip.nat[*].public_ip
    public_subnets_cidr_blocks = aws_subnet.public_subnets[*].cidr_block
    nat_gateway_count          = length(aws_nat_gateway.nat)
    az_public_subnets_cidrs = length(aws_subnet.public_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(aws_subnet.public_subnets)) :
        aws_subnet.public_subnets[j].cidr_block if j % length(local.actual_azs) == i
      ]
    } : {}
    az_private_subnets_cidrs = length(aws_subnet.private_subnets) > 0 ? {
      for i, az in local.actual_azs : az => [
        for j in range(length(aws_subnet.private_subnets)) :
        aws_subnet.private_subnets[j].cidr_block if j % length(local.actual_azs) == i
      ]
    } : {}
  }
}