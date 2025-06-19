locals {
  additional_k8s_subnets = [cidrsubnet(var.cluster.vpcCIDR, 4, 4), cidrsubnet(var.cluster.vpcCIDR, 4, 5), cidrsubnet(var.cluster.vpcCIDR, 4, 6), cidrsubnet(var.cluster.vpcCIDR, 4, 7)]
  private_subnets        = [cidrsubnet(var.cluster.vpcCIDR, 4, 0), cidrsubnet(var.cluster.vpcCIDR, 4, 1), cidrsubnet(var.cluster.vpcCIDR, 4, 2), cidrsubnet(var.cluster.vpcCIDR, 4, 3)]
  public_subnets         = [cidrsubnet(var.cluster.vpcCIDR, 4, 14), cidrsubnet(var.cluster.vpcCIDR, 4, 15)]
  default_networking_config = {
    "redundancy_strategy" : "MAXIMUM"
  }
  networking_config   = try(jsondecode(file("../stacks/${var.cluster.stackName}/networking.json")), local.default_networking_config)
  redundancy_strategy = lookup(local.networking_config, "redundancy_strategy", local.default_networking_config.redundancy_strategy)
  include_cluster_code_in_name   = var.include_cluster_code
  cluster_name_original          = "${substr(var.cluster.name, 0, 38 - 12)}-k8s-cluster"
  cluster_name_trimmed           = "${substr(var.cluster.name, 0, 38 - 11 - 12)}-${var.cluster.clusterCode}-k8s-cluster"
  cluster_name_to_use            = local.include_cluster_code_in_name ? local.cluster_name_trimmed : local.cluster_name_original

  tags = {
    Cluster                  = var.cluster.name
    facetsclustername        = var.cluster.name
    facetsclusterid          = var.cluster.id
    FacetsControlPlane       = var.cc_metadata.cc_host
    "karpenter.sh/discovery" = "${local.cluster_name_to_use}"
  }
  spec                             = lookup(var.instance, "spec", {})
  vpc_endpoints                    = lookup(local.spec, "vpc_endpoints", {})
  s3_service_endpoint              = lookup(local.vpc_endpoints, "s3_service", {})
  s3_service_endpoint_enabled      = lookup(local.s3_service_endpoint, "enabled", true)
  ec2_k8s_service_endpoint         = lookup(local.vpc_endpoints, "ec2_k8s_service", {})
  ec2_k8s_service_endpoint_enabled = lookup(local.ec2_k8s_service_endpoint, "enabled", true)
  ec2_vm_service_endpoint          = lookup(local.vpc_endpoints, "ec2_vm_service", {})
  ec2_vm_service_endpoint_enabled  = lookup(local.ec2_vm_service_endpoint, "enabled", true)
  
  # NAT Gateway configuration
  use_existing_nat_gateways = lookup(local.spec, "use_existing_nat_gateways", false)
  existing_nat_gateway_ids  = lookup(local.spec, "existing_nat_gateway_ids", [])
  should_create_nat_gateways = !local.use_existing_nat_gateways || length(local.existing_nat_gateway_ids) == 0
}

module "vpc" {
  source = "./terraform-aws-vpc-2.23.0"

  name = "${var.cluster.name}-vpc"
  cidr = var.cluster.vpcCIDR

  azs             = var.availability_zones
  private_subnets = concat(local.private_subnets, local.additional_k8s_subnets)
  public_subnets  = local.public_subnets

  enable_dns_hostnames    = true
  enable_nat_gateway      = local.should_create_nat_gateways
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Terraform                                               = "true",
    "kubernetes.io/cluster/${var.cluster.name}-k8s-cluster" = "shared"
    "kubernetes.io/cluster/${local.cluster_name_trimmed}"   = "shared"
  })
  # version    = "2.23.0"
  create_vpc = length(var.cluster.providedVPCId) > 0 ? false : true

  one_nat_gateway_per_az = var.settings.MULTI_AZ ? true : false
  single_nat_gateway     = var.settings.MULTI_AZ ? false : true
  public_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/elb" = 1
  })
  private_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/internal-elb" = 1
  })
  network_firewall_enabled = var.network_firewall_enabled
}

module "existing-vpc" {
  source                = "./terraform-aws-vpc"
  name                  = "${var.cluster.name}-vpc"
  secondary_cidr_blocks = [var.cluster.vpcCIDR]
  azs                   = var.cluster.azs
  private_subnets       = concat(local.private_subnets, local.additional_k8s_subnets)
  public_subnets        = local.public_subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    facetsclustername        = var.cluster.name
    Cluster                  = var.cluster.name
    FacetsControlPlane       = var.cc_metadata.cc_host
    "karpenter.sh/discovery" = "${local.cluster_name_to_use}"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    facetsclustername                 = var.cluster.name
    Cluster                           = var.cluster.name
    FacetsControlPlane                = var.cc_metadata.cc_host
    "karpenter.sh/discovery"          = "${local.cluster_name_to_use}"
  }
  enable_nat_gateway      = local.should_create_nat_gateways
  map_public_ip_on_launch = false

  tags = {
    Terraform                                               = "true",
    "kubernetes.io/cluster/${var.cluster.name}-k8s-cluster" = "shared"
    "kubernetes.io/cluster/${local.cluster_name_trimmed}"   = "shared"
    facetsclustername                                       = var.cluster.name
    Cluster                                                 = var.cluster.name
    FacetsControlPlane                                      = var.cc_metadata.cc_host
    "karpenter.sh/discovery"                                = "${local.cluster_name_to_use}"
  }
  existing_vpc_id          = length(var.cluster.providedVPCId) > 0 ? var.cluster.providedVPCId : ""
  create_components        = length(var.cluster.providedVPCId) > 0 ? true : false
  one_nat_gateway_per_az   = var.settings.MULTI_AZ ? true : false
  single_nat_gateway       = var.settings.MULTI_AZ ? false : true
  network_firewall_enabled = var.network_firewall_enabled
}

resource "random_string" "secgrp_suffix" {
  length           = 4
  override_special = "@$"
}

resource "aws_security_group" "allow_all_default" {
  name        = "allow_all_${var.cluster.name}-default-${random_string.secgrp_suffix.result}"
  vpc_id      = length(var.cluster.providedVPCId) > 0 ? module.existing-vpc.vpc_id : module.vpc.vpc_id
  description = "Allowing connection from within vpc"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cluster.vpcCIDR]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = local.tags
}

resource "aws_vpc_endpoint" "s3_service_endpoint" {
  count = local.s3_service_endpoint_enabled ? 1 : 0

  service_name        = "com.amazonaws.${var.cluster.awsRegion}.s3"
  vpc_id              = length(var.cluster.providedVPCId) > 0 ? module.existing-vpc.vpc_id : module.vpc.vpc_id
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = length(var.cluster.providedVPCId) > 0 ? module.existing-vpc.private_route_table_ids : module.vpc.private_route_table_ids
  private_dns_enabled = false
  auto_accept         = true
  tags = merge(local.tags, {
    Name = "${var.cluster.name}-s3vpc-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2_k8s_service_endpoint" {
  count = local.ec2_k8s_service_endpoint_enabled ? 1 : 0

  service_name        = "com.amazonaws.${var.cluster.awsRegion}.ec2"
  vpc_id              = length(var.cluster.providedVPCId) > 0 ? module.existing-vpc.vpc_id : module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [local.vpc_outputs.k8s_subnets[0], local.vpc_outputs.k8s_subnets[1]]
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.allow_all_default.id]
  auto_accept         = true
  tags = {
    Name               = "${var.cluster.name}-k8s-ec2vpc-endpoint"
    facetsclustername  = var.cluster.name
    Cluster            = var.cluster.name
    FacetsControlPlane = var.cc_metadata.cc_host
  }
}

resource "aws_vpc_endpoint" "ec2_vm_service_endpoint" {
  count = local.ec2_vm_service_endpoint_enabled ? 1 : 0

  service_name        = "com.amazonaws.${var.cluster.awsRegion}.ec2"
  vpc_id              = length(var.cluster.providedVPCId) > 0 ? module.existing-vpc.vpc_id : module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.vpc_outputs.private_subnets
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.allow_all_default.id]
  auto_accept         = true
  tags = {
    Name               = "${var.cluster.name}-ec2vpc-endpoint"
    facetsclustername  = var.cluster.name
    Cluster            = var.cluster.name
    FacetsControlPlane = var.cc_metadata.cc_host
  }
}

