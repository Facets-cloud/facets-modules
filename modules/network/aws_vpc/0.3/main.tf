# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Calculate subnet CIDRs
locals {
  vpc_cidr        = var.instance.spec.vpc_cidr
  azs             = var.instance.spec.azs
  enable_multi_az = var.instance.spec.enable_multi_az
  create_new_vpc  = var.instance.spec.choose_vpc_type == "create_new_vpc"
  existing_vpc_id = var.instance.spec.existing_vpc_id

  # Subnet calculations
  additional_k8s_subnets = [
    cidrsubnet(local.vpc_cidr, 4, 4),
    cidrsubnet(local.vpc_cidr, 4, 5),
    cidrsubnet(local.vpc_cidr, 4, 6),
    cidrsubnet(local.vpc_cidr, 4, 7)
  ]
  private_subnets = [
    cidrsubnet(local.vpc_cidr, 4, 0),
    cidrsubnet(local.vpc_cidr, 4, 1),
    cidrsubnet(local.vpc_cidr, 4, 2),
    cidrsubnet(local.vpc_cidr, 4, 3)
  ]
  public_subnets = [
    cidrsubnet(local.vpc_cidr, 4, 14),
    cidrsubnet(local.vpc_cidr, 4, 15)
  ]

  # Multi-AZ configuration
  actual_azs = local.enable_multi_az ? slice(local.azs, 0, min(2, length(local.azs))) : [local.azs[0]]

  # Tags for resources
  common_tags = merge(var.environment.cloud_tags, {
    Name                     = "${var.instance_name}-vpc"
    instance_name            = var.instance_name
    environment              = var.environment.name
    "karpenter.sh/discovery" = "${var.instance_name}-k8s-cluster"
  })

  # Kubernetes cluster tags
  k8s_cluster_tags = {
    "kubernetes.io/cluster/${var.instance_name}-k8s-cluster" = "shared"
  }
}

# VPC Module for new VPC creation
module "vpc" {
  count   = local.create_new_vpc ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.instance_name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.actual_azs
  private_subnets = concat(local.private_subnets, local.additional_k8s_subnets)
  public_subnets  = local.public_subnets

  enable_dns_hostnames    = true
  enable_dns_support      = true
  enable_nat_gateway      = true
  map_public_ip_on_launch = false

  # Multi-AZ NAT Gateway configuration
  one_nat_gateway_per_az = local.enable_multi_az
  single_nat_gateway     = !local.enable_multi_az

  public_subnet_tags = merge(local.common_tags, local.k8s_cluster_tags, {
    "kubernetes.io/role/elb" = "1"
  })

  private_subnet_tags = merge(local.common_tags, local.k8s_cluster_tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })

  tags = merge(local.common_tags, local.k8s_cluster_tags, {
    Terraform = "true"
  })
}

# Data source for existing VPC
data "aws_vpc" "existing" {
  count = local.create_new_vpc ? 0 : 1
  id    = local.existing_vpc_id
}

# Subnets for existing VPC scenario
resource "aws_subnet" "private_subnets" {
  count = local.create_new_vpc ? 0 : length(concat(local.private_subnets, local.additional_k8s_subnets))

  vpc_id            = data.aws_vpc.existing[0].id
  cidr_block        = concat(local.private_subnets, local.additional_k8s_subnets)[count.index]
  availability_zone = local.actual_azs[count.index % length(local.actual_azs)]

  tags = merge(local.common_tags, local.k8s_cluster_tags, {
    Name                              = "${var.instance_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "public_subnets" {
  count = local.create_new_vpc ? 0 : length(local.public_subnets)

  vpc_id                  = data.aws_vpc.existing[0].id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.actual_azs[count.index % length(local.actual_azs)]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, local.k8s_cluster_tags, {
    Name                     = "${var.instance_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

# Internet Gateway for existing VPC
resource "aws_internet_gateway" "existing_vpc_igw" {
  count  = local.create_new_vpc ? 0 : 1
  vpc_id = data.aws_vpc.existing[0].id

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-igw"
  })
}

# NAT Gateway for existing VPC
resource "aws_eip" "nat" {
  count  = local.create_new_vpc ? 0 : (local.enable_multi_az ? length(local.actual_azs) : 1)
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.existing_vpc_igw]
}

resource "aws_nat_gateway" "nat" {
  count = local.create_new_vpc ? 0 : (local.enable_multi_az ? length(local.actual_azs) : 1)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.existing_vpc_igw]
}

# Route tables for existing VPC
resource "aws_route_table" "public" {
  count  = local.create_new_vpc ? 0 : 1
  vpc_id = data.aws_vpc.existing[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.existing_vpc_igw[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = local.create_new_vpc ? 0 : (local.enable_multi_az ? length(local.actual_azs) : 1)
  vpc_id = data.aws_vpc.existing[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-private-rt-${count.index + 1}"
  })
}

# Route table associations for existing VPC
resource "aws_route_table_association" "public" {
  count = local.create_new_vpc ? 0 : length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = local.create_new_vpc ? 0 : length(aws_subnet.private_subnets)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

# Security Group
resource "aws_security_group" "allow_all_default" {
  name        = "allow_all_${var.instance_name}-default"
  vpc_id      = local.create_new_vpc ? module.vpc[0].vpc_id : data.aws_vpc.existing[0].id
  description = "Allowing connection from within vpc"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
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

  tags = local.common_tags
}

# VPC Endpoints
resource "aws_vpc_endpoint" "s3" {
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_id            = local.create_new_vpc ? module.vpc[0].vpc_id : data.aws_vpc.existing[0].id
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.create_new_vpc ? module.vpc[0].private_route_table_ids : aws_route_table.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2" {
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_id              = local.create_new_vpc ? module.vpc[0].vpc_id : data.aws_vpc.existing[0].id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.create_new_vpc ? slice(module.vpc[0].private_subnets, 2, 4) : slice(aws_subnet.private_subnets[*].id, 2, 4)
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.allow_all_default.id]

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-ec2-endpoint"
  })
}