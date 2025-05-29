# Local values for calculations
locals {
  # Calculate subnet mask from IP count
  subnet_mask_map = {
    "256"  = 24 # /24 = 256 IPs
    "512"  = 23 # /23 = 512 IPs  
    "1024" = 22 # /22 = 1024 IPs
    "2048" = 21 # /21 = 2048 IPs
    "4096" = 20 # /20 = 4096 IPs
    "8192" = 19 # /19 = 8192 IPs
  }

  public_subnet_newbits = local.subnet_mask_map[var.instance.spec.public_subnets.subnet_size] - tonumber(split("/", var.instance.spec.vpc_cidr)[1])
  eks_subnet_newbits    = local.subnet_mask_map[var.instance.spec.eks_subnets.subnet_size] - tonumber(split("/", var.instance.spec.vpc_cidr)[1])

  # Create list of all public subnets needed
  public_subnets = flatten([
    for az_index, az in var.instance.spec.availability_zones : [
      for subnet_index in range(var.instance.spec.public_subnets.count_per_az) : {
        az_index     = az_index
        subnet_index = subnet_index
        az           = az
        cidr_index   = az_index * var.instance.spec.public_subnets.count_per_az + subnet_index
      }
    ]
  ])

  # Create list of all EKS private subnets (one per AZ)
  eks_subnets = [
    for az_index, az in var.instance.spec.availability_zones : {
      az_index   = az_index
      az         = az
      cidr_index = length(local.public_subnets) + az_index
    }
  ]

  # VPC endpoints configuration with defaults
  vpc_endpoints = var.instance.spec.vpc_endpoints != null ? var.instance.spec.vpc_endpoints : {
    enable_s3           = true
    enable_dynamodb     = true
    enable_ecr_api      = true
    enable_ecr_dkr      = true
    enable_eks          = false
    enable_ec2          = false
    enable_ssm          = true
    enable_ssm_messages = true
    enable_ec2_messages = true
    enable_kms          = false
    enable_logs         = false
    enable_monitoring   = false
    enable_sts          = false
    enable_lambda       = false
  }

  # Resource naming prefix
  name_prefix = "${var.environment.unique_name}-${var.instance_name}"

  # Common tags
  common_tags = merge(
    var.environment.cloud_tags,
    {
      Name        = local.name_prefix
      Environment = var.environment.name
    }
  )

  # EKS tags for subnet discovery
  eks_tags = {
    "kubernetes.io/role/elb"                                              = "1"
    "kubernetes.io/cluster/${var.instance.spec.eks_subnets.cluster_name}" = "shared"
  }

  eks_private_tags = {
    "kubernetes.io/role/internal-elb"                                     = "1"
    "kubernetes.io/cluster/${var.instance.spec.eks_subnets.cluster_name}" = "shared"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.instance.spec.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = {
    for subnet in local.public_subnets :
    "${subnet.az}-${subnet.subnet_index}" => subnet
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.instance.spec.vpc_cidr, local.public_subnet_newbits, each.value.cidr_index)
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, local.eks_tags, {
    Name = "${local.name_prefix}-public-${each.value.az}-${each.value.subnet_index + 1}"
    Type = "Public"
  })
}

# EKS Private Subnets
resource "aws_subnet" "private" {
  for_each = {
    for subnet in local.eks_subnets :
    subnet.az => subnet
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.instance.spec.vpc_cidr, local.eks_subnet_newbits, each.value.cidr_index)
  availability_zone = each.value.az

  tags = merge(local.common_tags, local.eks_private_tags, {
    Name = "${local.name_prefix}-private-${each.value.az}"
    Type = "Private"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in var.instance.spec.availability_zones : az => az

    } : {
    single = var.instance.spec.availability_zones[0]
  }

  tags = merge(local.common_tags, {
    Name = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-eip-${each.key}" : "${local.name_prefix}-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in var.instance.spec.availability_zones : az => az
    } : {
    single = var.instance.spec.availability_zones[0]
  }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = var.instance.spec.nat_gateway.strategy == "per_az" ? aws_subnet.public["${each.key}-0"].id : aws_subnet.public["${var.instance.spec.availability_zones[0]}-0"].id

  tags = merge(local.common_tags, {
    Name = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-nat-${each.key}" : "${local.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables
resource "aws_route_table" "private" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in var.instance.spec.availability_zones : az => az
    } : {
    single = "single"
  }

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.instance.spec.nat_gateway.strategy == "per_az" ? aws_nat_gateway.main[each.key].id : aws_nat_gateway.main["single"].id
  }

  tags = merge(local.common_tags, {
    Name = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-private-rt-${each.key}" : "${local.name_prefix}-private-rt"
  })
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = var.instance.spec.nat_gateway.strategy == "per_az" ? aws_route_table.private[each.key].id : aws_route_table.private["single"].id
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = anytrue([
    try(local.vpc_endpoints.enable_ecr_api, false),
    try(local.vpc_endpoints.enable_ecr_dkr, false),
    try(local.vpc_endpoints.enable_eks, false),
    try(local.vpc_endpoints.enable_ec2, false),
    try(local.vpc_endpoints.enable_ssm, false),
    try(local.vpc_endpoints.enable_ssm_messages, false),
    try(local.vpc_endpoints.enable_ec2_messages, false),
    try(local.vpc_endpoints.enable_kms, false),
    try(local.vpc_endpoints.enable_logs, false),
    try(local.vpc_endpoints.enable_monitoring, false),
    try(local.vpc_endpoints.enable_sts, false),
    try(local.vpc_endpoints.enable_lambda, false)
  ]) ? 1 : 0

  name_prefix = "${local.name_prefix}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.instance.spec.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-endpoints-sg"
  })
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = try(local.vpc_endpoints.enable_s3, false) ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.instance.spec.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    values(aws_route_table.private)[*].id
  )

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-endpoint"
  })
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = try(local.vpc_endpoints.enable_dynamodb, false) ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.instance.spec.region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    values(aws_route_table.private)[*].id
  )

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-dynamodb-endpoint"
  })
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count = try(local.vpc_endpoints.enable_ecr_api, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-api-endpoint"
  })
}

# ECR Docker Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = try(local.vpc_endpoints.enable_ecr_dkr, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-dkr-endpoint"
  })
}

# EKS Interface Endpoint
resource "aws_vpc_endpoint" "eks" {
  count = try(local.vpc_endpoints.enable_eks, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-endpoint"
  })
}

# EC2 Interface Endpoint
resource "aws_vpc_endpoint" "ec2" {
  count = try(local.vpc_endpoints.enable_ec2, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-endpoint"
  })
}

# SSM Interface Endpoint
resource "aws_vpc_endpoint" "ssm" {
  count = try(local.vpc_endpoints.enable_ssm, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ssm-endpoint"
  })
}

# SSM Messages Interface Endpoint
resource "aws_vpc_endpoint" "ssm_messages" {
  count = try(local.vpc_endpoints.enable_ssm_messages, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ssm-messages-endpoint"
  })
}

# EC2 Messages Interface Endpoint
resource "aws_vpc_endpoint" "ec2_messages" {
  count = try(local.vpc_endpoints.enable_ec2_messages, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-messages-endpoint"
  })
}

# KMS Interface Endpoint
resource "aws_vpc_endpoint" "kms" {
  count = try(local.vpc_endpoints.enable_kms, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-kms-endpoint"
  })
}

# CloudWatch Logs Interface Endpoint
resource "aws_vpc_endpoint" "logs" {
  count = try(local.vpc_endpoints.enable_logs, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-logs-endpoint"
  })
}

# CloudWatch Monitoring Interface Endpoint
resource "aws_vpc_endpoint" "monitoring" {
  count = try(local.vpc_endpoints.enable_monitoring, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-monitoring-endpoint"
  })
}

# STS Interface Endpoint
resource "aws_vpc_endpoint" "sts" {
  count = try(local.vpc_endpoints.enable_sts, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sts-endpoint"
  })
}

# Lambda Interface Endpoint
resource "aws_vpc_endpoint" "lambda" {
  count = try(local.vpc_endpoints.enable_lambda, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.instance.spec.region}.lambda"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-endpoint"
  })
}
