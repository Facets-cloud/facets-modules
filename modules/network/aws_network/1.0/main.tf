# Data source to get all available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for calculations
locals {
  # Determine which availability zones to use - ensure we have enough AZs for auto selection
  selected_azs = lookup(var.instance.spec, "auto_select_azs", false) ? (
    length(data.aws_availability_zones.available.names) >= 3 ?
    slice(data.aws_availability_zones.available.names, 0, 3) :
    data.aws_availability_zones.available.names
  ) : lookup(var.instance.spec, "availability_zones", [])

  # Calculate subnet mask from IP count
  subnet_mask_map = {
    "256"  = 24 # /24 = 256 IPs
    "512"  = 23 # /23 = 512 IPs  
    "1024" = 22 # /22 = 1024 IPs
    "2048" = 21 # /21 = 2048 IPs
    "4096" = 20 # /20 = 4096 IPs
    "8192" = 19 # /19 = 8192 IPs
  }

  vpc_prefix_length = tonumber(split("/", var.instance.spec.vpc_cidr)[1])

  public_subnet_newbits   = local.subnet_mask_map[var.instance.spec.public_subnets.subnet_size] - local.vpc_prefix_length
  private_subnet_newbits  = local.subnet_mask_map[var.instance.spec.private_subnets.subnet_size] - local.vpc_prefix_length
  database_subnet_newbits = local.subnet_mask_map[var.instance.spec.database_subnets.subnet_size] - local.vpc_prefix_length

  # Calculate total number of subnets needed
  public_total_subnets   = length(local.selected_azs) * var.instance.spec.public_subnets.count_per_az
  private_total_subnets  = length(local.selected_azs) * var.instance.spec.private_subnets.count_per_az
  database_total_subnets = length(local.selected_azs) * var.instance.spec.database_subnets.count_per_az

  # Create list of newbits for cidrsubnets function
  # Order: public subnets, private subnets, database subnets
  subnet_newbits = concat(
    var.instance.spec.public_subnets.count_per_az > 0 ? [
      for i in range(local.public_total_subnets) : local.public_subnet_newbits
    ] : [],
    [for i in range(local.private_total_subnets) : local.private_subnet_newbits],
    [for i in range(local.database_total_subnets) : local.database_subnet_newbits]
  )

  # Generate all subnet CIDRs using cidrsubnets function - this prevents overlaps
  all_subnet_cidrs = cidrsubnets(var.instance.spec.vpc_cidr, local.subnet_newbits...)

  # Extract subnet CIDRs by type
  public_subnet_cidrs = var.instance.spec.public_subnets.count_per_az > 0 ? slice(
    local.all_subnet_cidrs,
    0,
    local.public_total_subnets
  ) : []

  private_subnet_cidrs = slice(
    local.all_subnet_cidrs,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets : 0,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets + local.private_total_subnets : local.private_total_subnets
  )

  database_subnet_cidrs = slice(
    local.all_subnet_cidrs,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets + local.private_total_subnets : local.private_total_subnets,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets + local.private_total_subnets + local.database_total_subnets : local.private_total_subnets + local.database_total_subnets
  )

  # Create subnet mappings with AZ and CIDR
  public_subnets = var.instance.spec.public_subnets.count_per_az > 0 ? flatten([
    for az_index, az in local.selected_azs : [
      for subnet_index in range(var.instance.spec.public_subnets.count_per_az) : {
        az_index     = az_index
        subnet_index = subnet_index
        az           = az
        cidr_block   = local.public_subnet_cidrs[az_index * var.instance.spec.public_subnets.count_per_az + subnet_index]
      }
    ]
  ]) : []

  private_subnets = flatten([
    for az_index, az in local.selected_azs : [
      for subnet_index in range(var.instance.spec.private_subnets.count_per_az) : {
        az_index     = az_index
        subnet_index = subnet_index
        az           = az
        cidr_block   = local.private_subnet_cidrs[az_index * var.instance.spec.private_subnets.count_per_az + subnet_index]
      }
    ]
  ])

  database_subnets = flatten([
    for az_index, az in local.selected_azs : [
      for subnet_index in range(var.instance.spec.database_subnets.count_per_az) : {
        az_index     = az_index
        subnet_index = subnet_index
        az           = az
        cidr_block   = local.database_subnet_cidrs[az_index * var.instance.spec.database_subnets.count_per_az + subnet_index]
      }
    ]
  ])

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
    lookup(var.instance.spec, "tags", {}),
    {
      Name        = local.name_prefix
      Environment = var.environment.name
    }
  )

  # EKS tags for public subnets (for external load balancers)
  eks_public_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # EKS tags for private subnets (for internal load balancers)
  eks_private_tags = {
    "kubernetes.io/role/internal-elb" = "1"
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
  for_each = var.instance.spec.public_subnets.count_per_az > 0 ? {
    for subnet in local.public_subnets :
    "${subnet.az}-${subnet.subnet_index}" => subnet
  } : {}

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, local.eks_public_tags, {
    Name = "${local.name_prefix}-public-${each.value.az}-${each.value.subnet_index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = {
    for subnet in local.private_subnets :
    "${subnet.az}-${subnet.subnet_index}" => subnet
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(local.common_tags, local.eks_private_tags, {
    Name = "${local.name_prefix}-private-${each.value.az}-${each.value.subnet_index + 1}"
    Type = "Private"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  for_each = {
    for subnet in local.database_subnets :
    "${subnet.az}-${subnet.subnet_index}" => subnet
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-${each.value.az}-${each.value.subnet_index + 1}"
    Type = "Database"
  })
}

# Database Subnet Group
resource "aws_db_subnet_group" "database" {
  name       = "${local.name_prefix}-database-subnet-group"
  subnet_ids = values(aws_subnet.database)[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-subnet-group"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in local.selected_azs : az => az
    } : var.instance.spec.public_subnets.count_per_az > 0 ? {
    single = local.selected_azs[0]
  } : {}

  tags = merge(local.common_tags, {
    Name = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-eip-${each.key}" : "${local.name_prefix}-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in local.selected_azs : az => az
    } : var.instance.spec.public_subnets.count_per_az > 0 ? {
    single = local.selected_azs[0]
  } : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = var.instance.spec.nat_gateway.strategy == "per_az" ? aws_subnet.public["${each.key}-0"].id : aws_subnet.public["${local.selected_azs[0]}-0"].id

  tags = merge(local.common_tags, {
    Name = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-nat-${each.key}" : "${local.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  count = var.instance.spec.public_subnets.count_per_az > 0 ? 1 : 0

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
  route_table_id = aws_route_table.public[0].id
}

# Private Route Tables
resource "aws_route_table" "private" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in local.selected_azs : az => az
    } : var.instance.spec.public_subnets.count_per_az > 0 ? {
    single = "single"
  } : {}

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.instance.spec.public_subnets.count_per_az > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.instance.spec.nat_gateway.strategy == "per_az" ? aws_nat_gateway.main[each.key].id : aws_nat_gateway.main["single"].id
    }
  }

  tags = merge(local.common_tags, {
    Name = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-private-rt-${each.key}" : "${local.name_prefix}-private-rt"
  })
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = var.instance.spec.nat_gateway.strategy == "per_az" ? aws_route_table.private[each.value.availability_zone].id : aws_route_table.private["single"].id
}

# Database Route Tables (isolated - no internet access)
resource "aws_route_table" "database" {
  for_each = {
    for az in local.selected_azs : az => az
  }

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-rt-${each.key}"
  })
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[each.value.availability_zone].id
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
  service_name      = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    var.instance.spec.public_subnets.count_per_az > 0 ? [aws_route_table.public[0].id] : [],
    values(aws_route_table.private)[*].id,
    values(aws_route_table.database)[*].id
  )

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-endpoint"
  })
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = try(local.vpc_endpoints.enable_dynamodb, false) ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    var.instance.spec.public_subnets.count_per_az > 0 ? [aws_route_table.public[0].id] : [],
    values(aws_route_table.private)[*].id,
    values(aws_route_table.database)[*].id
  )

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-dynamodb-endpoint"
  })
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count = try(local.vpc_endpoints.enable_ecr_api, false) ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.ecr.api"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.ecr.dkr"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.eks"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.ec2"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.ssm"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.ssmmessages"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.ec2messages"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.kms"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.logs"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.monitoring"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.sts"
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
  service_name        = "com.amazonaws.${var.inputs.cloud_account.attributes.aws_region}.lambda"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-endpoint"
  })
}