# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Calculate subnet CIDRs
locals {
  vpc_cidr                 = var.instance.spec.vpc_cidr
  azs                      = var.instance.spec.azs
  enable_multi_az          = var.instance.spec.enable_multi_az
  create_new_vpc           = var.instance.spec.choose_vpc_type == "create_new_vpc"
  existing_vpc_id          = var.instance.spec.existing_vpc_id
  nat_gateway_strategy     = var.instance.spec.nat_gateway_strategy
  create_new_nat_gateways  = local.nat_gateway_strategy == "create_new_nat_gateways"
  existing_nat_gateway_ids = var.instance.spec.existing_nat_gateway_ids != "" ? split(",", trimspace(var.instance.spec.existing_nat_gateway_ids)) : []

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

# VPC Module for new VPC creation (only when creating new NAT Gateways)
module "vpc" {
  count  = local.create_new_vpc && local.create_new_nat_gateways ? 1 : 0
  source = "./terraform-aws-vpc-5.0.0"

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

# VPC resource for new VPC creation (when using existing NAT Gateways)
resource "aws_vpc" "new_vpc" {
  count                = local.create_new_vpc && !local.create_new_nat_gateways ? 1 : 0
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, local.k8s_cluster_tags, {
    Name      = "${var.instance_name}-vpc"
    Terraform = "true"
  })
}

# Subnets for new VPC with existing NAT Gateways
resource "aws_subnet" "new_vpc_private_subnets" {
  count = local.create_new_vpc && !local.create_new_nat_gateways ? length(concat(local.private_subnets, local.additional_k8s_subnets)) : 0

  vpc_id            = aws_vpc.new_vpc[0].id
  cidr_block        = concat(local.private_subnets, local.additional_k8s_subnets)[count.index]
  availability_zone = local.actual_azs[count.index % length(local.actual_azs)]

  tags = merge(local.common_tags, local.k8s_cluster_tags, {
    Name                              = "${var.instance_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "new_vpc_public_subnets" {
  count = local.create_new_vpc && !local.create_new_nat_gateways ? length(local.public_subnets) : 0

  vpc_id                  = aws_vpc.new_vpc[0].id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.actual_azs[count.index % length(local.actual_azs)]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, local.k8s_cluster_tags, {
    Name                     = "${var.instance_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

# Data source for existing VPC
data "aws_vpc" "existing" {
  count = local.create_new_vpc ? 0 : 1
  id    = local.existing_vpc_id
}

# Check for existing Internet Gateway in existing VPC
data "aws_internet_gateway" "existing" {
  count = !local.create_new_vpc ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing[0].id]
  }
}

# Data sources for existing NAT Gateways (works for both new and existing VPC scenarios)
data "aws_nat_gateway" "existing" {
  count = !local.create_new_nat_gateways ? length(local.existing_nat_gateway_ids) : 0
  id    = local.existing_nat_gateway_ids[count.index]
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

# Internet Gateway for existing VPC (create only if none exists)
resource "aws_internet_gateway" "existing_vpc_igw" {
  count  = !local.create_new_vpc && length(data.aws_internet_gateway.existing) == 0 ? 1 : 0
  vpc_id = data.aws_vpc.existing[0].id

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-igw"
  })
}

# Internet Gateway for new VPC with existing NAT Gateways
resource "aws_internet_gateway" "new_vpc_igw" {
  count  = local.create_new_vpc && !local.create_new_nat_gateways ? 1 : 0
  vpc_id = aws_vpc.new_vpc[0].id

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-igw"
  })
}

# NAT Gateway for existing VPC (only when creating new NAT Gateways)
resource "aws_eip" "nat" {
  count = !local.create_new_vpc && local.create_new_nat_gateways ? (local.enable_multi_az ? length(local.actual_azs) : 1) : 0

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-nat-eip-${count.index + 1}"
  })

  depends_on = [
    aws_internet_gateway.existing_vpc_igw,
    data.aws_internet_gateway.existing
  ]
}

resource "aws_nat_gateway" "nat" {
  count = !local.create_new_vpc && local.create_new_nat_gateways ? (local.enable_multi_az ? length(local.actual_azs) : 1) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-nat-${count.index + 1}"
  })

  depends_on = [
    aws_internet_gateway.existing_vpc_igw,
    data.aws_internet_gateway.existing
  ]
}

# Public route table for existing VPC (always create our own)
resource "aws_route_table" "public" {
  count  = !local.create_new_vpc ? 1 : 0
  vpc_id = data.aws_vpc.existing[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = length(data.aws_internet_gateway.existing) > 0 ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.existing_vpc_igw[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-public-rt"
  })
}

# Public route table for new VPC with existing NAT Gateways
resource "aws_route_table" "new_vpc_public" {
  count  = local.create_new_vpc && !local.create_new_nat_gateways ? 1 : 0
  vpc_id = aws_vpc.new_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.new_vpc_igw[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-public-rt"
  })
}

# Private route tables for existing VPC
resource "aws_route_table" "private" {
  count  = !local.create_new_vpc ? (local.enable_multi_az ? length(local.actual_azs) : 1) : 0
  vpc_id = data.aws_vpc.existing[0].id

  dynamic "route" {
    for_each = local.create_new_nat_gateways ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[count.index].id
    }
  }

  dynamic "route" {
    for_each = !local.create_new_nat_gateways ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = data.aws_nat_gateway.existing[count.index].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-private-rt-${count.index + 1}"
  })
}

# Private route tables for new VPC with existing NAT Gateways
resource "aws_route_table" "new_vpc_private" {
  count  = local.create_new_vpc && !local.create_new_nat_gateways ? (local.enable_multi_az ? length(local.actual_azs) : 1) : 0
  vpc_id = aws_vpc.new_vpc[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.existing[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-private-rt-${count.index + 1}"
  })
}

# Route table associations for existing VPC
resource "aws_route_table_association" "public" {
  count = !local.create_new_vpc ? length(aws_subnet.public_subnets) : 0

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = !local.create_new_vpc ? length(aws_subnet.private_subnets) : 0

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

# Route table associations for new VPC with existing NAT Gateways
resource "aws_route_table_association" "new_vpc_public" {
  count = local.create_new_vpc && !local.create_new_nat_gateways ? length(aws_subnet.new_vpc_public_subnets) : 0

  subnet_id      = aws_subnet.new_vpc_public_subnets[count.index].id
  route_table_id = aws_route_table.new_vpc_public[0].id
}

resource "aws_route_table_association" "new_vpc_private" {
  count = local.create_new_vpc && !local.create_new_nat_gateways ? length(aws_subnet.new_vpc_private_subnets) : 0

  subnet_id      = aws_subnet.new_vpc_private_subnets[count.index].id
  route_table_id = aws_route_table.new_vpc_private[count.index % length(aws_route_table.new_vpc_private)].id
}

# Security Group
resource "aws_security_group" "allow_all_default" {
  name = "allow_all_${var.instance_name}-default"
  vpc_id = local.create_new_vpc ? (
    local.create_new_nat_gateways ? module.vpc[0].vpc_id : aws_vpc.new_vpc[0].id
  ) : data.aws_vpc.existing[0].id
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
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_id = local.create_new_vpc ? (
    local.create_new_nat_gateways ? module.vpc[0].vpc_id : aws_vpc.new_vpc[0].id
  ) : data.aws_vpc.existing[0].id
  vpc_endpoint_type = "Gateway"
  route_table_ids = local.create_new_vpc ? (
    local.create_new_nat_gateways ? module.vpc[0].private_route_table_ids : aws_route_table.new_vpc_private[*].id
  ) : aws_route_table.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2" {
  service_name = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_id = local.create_new_vpc ? (
    local.create_new_nat_gateways ? module.vpc[0].vpc_id : aws_vpc.new_vpc[0].id
  ) : data.aws_vpc.existing[0].id
  vpc_endpoint_type = "Interface"
  subnet_ids = local.create_new_vpc ? (
    local.create_new_nat_gateways ? slice(module.vpc[0].private_subnets, 2, 4) : slice(aws_subnet.new_vpc_private_subnets[*].id, 2, 4)
  ) : slice(aws_subnet.private_subnets[*].id, 2, 4)
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.allow_all_default.id]

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-ec2-endpoint"
  })
}
