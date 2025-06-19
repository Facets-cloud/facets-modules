locals {
  vpc_outputs = length(var.cluster.providedVPCId) > 0 ? {
    vpc_id                         = module.existing-vpc.vpc_id
    azs                            = var.availability_zones
    private_subnets                = try(slice(module.existing-vpc.private_subnets, 0, 2), [])
    k8s_subnets                    = length(module.existing-vpc.private_subnets) > 0 ? slice(module.existing-vpc.private_subnets, 2, 8) : []
    public_subnets                 = module.existing-vpc.public_subnets
    public_route_table_ids         = module.existing-vpc.public_route_table_ids
    private_route_table_ids        = module.existing-vpc.private_route_table_ids
    default_subnet_id              = try(module.existing-vpc.private_subnets[0], null)
    default_security_group_id      = aws_security_group.allow_all_default.id
    default_private_route_table_id = try(module.existing-vpc.private_route_table_ids[0], null)
    private_route_table_ids_list   = try(join(",", module.existing-vpc.private_route_table_ids), null)
    vpc_cidr                       = var.cluster.vpcCIDR
    az_subnets = {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.existing-vpc.private_subnets), 2) : module.existing-vpc.private_subnets[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.existing-vpc.private_subnets), 2) : module.existing-vpc.private_subnets[i]]
    }
    az_private_subnets = {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.existing-vpc.private_subnets), 2) : module.existing-vpc.private_subnets[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.existing-vpc.private_subnets), 2) : module.existing-vpc.private_subnets[i]]
    }
    az_public_subnets = {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.existing-vpc.public_subnets), 2) : module.existing-vpc.public_subnets[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.existing-vpc.public_subnets), 2) : module.existing-vpc.public_subnets[i]]
    }
    private_subnet_objects = {
      id   = try(slice(module.existing-vpc.private_subnets, 0, 2), [])
      cidr = try(slice(module.existing-vpc.private_subnets_cidr_blocks, 0, 2), [])
    }
    nat_gateway_ips            = []
    public_subnets_cidr_blocks = module.existing-vpc.public_subnets_cidr_blocks
    nat_gateway_count          = module.existing-vpc.nat_gateway_count
    az_public_subnets_cidrs = length(module.existing-vpc.public_subnets_cidr_blocks) > 0 ? {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.existing-vpc.public_subnets_cidr_blocks), 2) : module.existing-vpc.public_subnets_cidr_blocks[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.existing-vpc.public_subnets_cidr_blocks), 2) : module.existing-vpc.public_subnets_cidr_blocks[i]]
    } : null
    az_private_subnets_cidrs = length(module.existing-vpc.private_subnets_cidr_blocks) > 0 ? {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.existing-vpc.private_subnets_cidr_blocks), 2) : module.existing-vpc.private_subnets_cidr_blocks[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.existing-vpc.private_subnets_cidr_blocks), 2) : module.existing-vpc.private_subnets_cidr_blocks[i]]
    } : null
    } : {
    vpc_id                         = module.vpc.vpc_id
    azs                            = var.availability_zones
    private_subnets                = length(module.vpc.private_subnets) > 0 ? slice(module.vpc.private_subnets, 0, 2) : []
    k8s_subnets                    = length(module.vpc.private_subnets) > 0 ? slice(module.vpc.private_subnets, 2, 8) : []
    public_subnets                 = module.vpc.public_subnets
    public_route_table_ids         = module.vpc.public_route_table_ids
    private_route_table_ids        = module.vpc.private_route_table_ids
    default_subnet_id              = length(module.vpc.private_subnets) > 0 ? module.vpc.private_subnets[0] : null
    default_security_group_id      = aws_security_group.allow_all_default.id
    default_private_route_table_id = length(module.vpc.private_route_table_ids) > 0 ? module.vpc.private_route_table_ids[0] : null
    private_route_table_ids_list   = join(",", module.vpc.private_route_table_ids)
    vpc_cidr                       = module.vpc.vpc_cidr_block
    private_subnet_objects = {
      id   = try(slice(module.vpc.private_subnets, 0, 2), [])
      cidr = try(slice(module.vpc.private_subnets_cidr_blocks, 0, 2), [])
    }
    az_subnets = length(module.vpc.private_subnets) > 0 ? {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.vpc.private_subnets), 2) : module.vpc.private_subnets[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.vpc.private_subnets), 2) : module.vpc.private_subnets[i]]
    } : null
    az_private_subnets = length(module.vpc.private_subnets) > 0 ? {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.vpc.private_subnets), 2) : module.vpc.private_subnets[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.vpc.private_subnets), 2) : module.vpc.private_subnets[i]]
    } : null
    az_public_subnets = length(module.vpc.public_subnets) > 0 ? {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.vpc.public_subnets), 2) : module.vpc.public_subnets[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.vpc.public_subnets), 2) : module.vpc.public_subnets[i]]
    } : null
    nat_gateway_ips            = module.vpc.nat_public_ips
    public_subnets_cidr_blocks = module.vpc.public_subnets_cidr_blocks
    nat_gateway_count          = module.vpc.nat_gateway_count
    az_public_subnets_cidrs = length(module.vpc.public_subnets_cidr_blocks) > 0 ? {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.vpc.public_subnets_cidr_blocks), 2) : module.vpc.public_subnets_cidr_blocks[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.vpc.public_subnets_cidr_blocks), 2) : module.vpc.public_subnets_cidr_blocks[i]]
    } : null
    az_private_subnets_cidrs = length(module.vpc.private_subnets_cidr_blocks) > 0 ? {
      "${var.cluster.azs[0]}" = [for i in range(0, length(module.vpc.private_subnets_cidr_blocks), 2) : module.vpc.private_subnets_cidr_blocks[i]]
      "${var.cluster.azs[1]}" = [for i in range(1, length(module.vpc.private_subnets_cidr_blocks), 2) : module.vpc.private_subnets_cidr_blocks[i]]
    } : null
  }
}


output "vpc_details" {
  value = local.vpc_outputs
}