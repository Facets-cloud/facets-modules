module "vpc" {
  source                   = "./vpc"
  cluster                  = var.cluster
  cc_metadata              = var.cc_metadata
  settings                 = var.settings
  network_firewall_enabled = local.network_firewall_enabled
  availability_zones       = local.azs
  include_cluster_code     = var.include_cluster_code
  instance                 = var.instance
}

data "aws_caller_identity" "current" {}

module "network_firewall" {
  depends_on                        = [module.vpc, aws_subnet.firewall_subnets, module.rule_group]
  count                             = local.network_firewall_enabled ? 1 : 0
  source                            = "./terraform-aws-network-firewall"
  name                              = length("${var.cluster.name}-${var.instance_name}-nfw") > 128 ? md5("${var.cluster.name}-${var.instance_name}-nfw") : "${var.cluster.name}-${var.instance_name}-nfw"
  description                       = "Network firewall created via facets"
  delete_protection                 = lookup(local.advanced_network_firewall, "delete_protection", false)
  firewall_policy_change_protection = lookup(local.advanced_network_firewall, "firewall_policy_change_protection", false)
  subnet_change_protection          = lookup(local.advanced_network_firewall, "subnet_change_protection", false)
  vpc_id                            = module.vpc.vpc_details.vpc_id
  subnet_mapping = { for i in range(0, module.vpc.vpc_details.nat_gateway_count) :
    "subnet-${i}" => {
      subnet_id       = element(aws_subnet.firewall_subnets.*.id, i)
      ip_address_type = "IPV4"
    }
  }
  encryption_configuration     = lookup(local.advanced_network_firewall, "encryption_configuration", {})
  create_logging_configuration = local.create_logging_configuration
  logging_configuration_destination_config = concat(
    local.create_logging_configuration ?
    (local.alert_logging_configuration_destination == "cloudwatch" ? [
      {
        log_destination = {
          logGroup = aws_cloudwatch_log_group.logs[0].name
        }
        log_destination_type = "CloudWatchLogs"
        log_type             = "ALERT"
      }
      ] : [
      {
        log_destination = {
          bucketName = aws_s3_bucket.network_firewall_logs[0].id
          prefix     = "alert-log-${var.instance_name}"
        }
        log_destination_type = "S3"
        log_type             = "ALERT"
      }
    ]) : [],
    local.enable_s3_flowlog_configuration ? [
      {
        log_destination = {
          bucketName = aws_s3_bucket.network_firewall_logs[0].id
          prefix     = "flow-log-${var.instance_name}"
        }
        log_destination_type = "S3"
        log_type             = "FLOW"
      }
    ] : [],
    local.enable_cloud_watch_flow_log_configuration ? [
      {
        log_destination = {
          logGroup = aws_cloudwatch_log_group.logs[0].name
        }
        log_destination_type = "CloudWatchLogs"
        log_type             = "FLOW"
      }
    ] : [],
    lookup(local.advanced_network_firewall, "logging_configuration_destination_config", [])
  )
  policy_name = length("${var.cluster.name}-${var.instance_name}-nf-policy") > 63 ? md5("${var.cluster.name}-${var.instance_name}-nf-policy") : "${var.cluster.name}-${var.instance_name}-nf-policy"
  policy_stateful_rule_group_reference = {
    for k, v in local.rule_groups : k => {
      resource_arn = module.rule_group[k].arn
      priority     = lookup(v, "priority", null)
    }
    if(
      (lookup(v, "type", null) == "STATEFUL")
    )
  }
  policy_stateless_rule_group_reference = {
    for k, v in local.rule_groups : k => {
      resource_arn = module.rule_group[k].arn
      priority     = lookup(v, "priority", null)
    }
    if(
      (lookup(v, "type", null) == "STATELESS")
    )
  }
  policy_stateless_default_actions          = lookup(local.advanced_network_firewall, "policy_stateless_default_actions", ["aws:pass"])
  policy_stateless_fragment_default_actions = lookup(local.advanced_network_firewall, "policy_stateless_fragment_default_actions", ["aws:pass"])
  policy_stateless_custom_action            = lookup(local.advanced_network_firewall, "policy_stateless_custom_action", {})
  create_policy_resource_policy             = lookup(local.advanced_network_firewall, "create_policy_resource_policy", false)
  policy_resource_policy_actions            = lookup(local.advanced_network_firewall, "policy_resource_policy_actions", [])
  policy_resource_policy_principals         = lookup(local.advanced_network_firewall, "policy_resource_policy_principals", [])
  policy_attach_resource_policy             = lookup(local.advanced_network_firewall, "policy_attach_resource_policy", false)
  policy_resource_policy                    = lookup(local.advanced_network_firewall, "policy_resource_policy", "")
  policy_ram_resource_associations          = lookup(local.advanced_network_firewall, "policy_ram_resource_associations", {})
  policy_stateful_default_actions           = lookup(local.advanced_network_firewall, "policy_stateful_default_actions", [])
  policy_stateful_engine_options            = lookup(local.advanced_network_firewall, "policy_stateful_engine_options", {})
  tags                                      = merge(lookup(local.advanced_network_firewall, "tags", {}), local.tags)
  policy_tags                               = merge(lookup(local.advanced_network_firewall, "policy_tags", {}), local.tags)
  firewall_policy_arn                       = lookup(local.advanced_network_firewall, "firewall_policy_arn", "")
}

module "rule_group" {
  depends_on = [module.vpc]
  for_each = {
    for key, value in lookup(local.advanced_network_firewall, "rule_groups", {}) : key => value if local.network_firewall_enabled
  }
  source                     = "./terraform-aws-network-firewall/modules/rule-group"
  name                       = length("${var.cluster.name}-${var.instance_name}-${each.key}-rule-group") > 128 ? md5("${var.cluster.name}-${var.instance_name}-${each.key}-rule-group") : "${var.cluster.name}-${var.instance_name}-${each.key}-rule-group"
  description                = lookup(each.value, "description", null)
  type                       = lookup(each.value, "type", "STATELESS")
  capacity                   = lookup(each.value, "capacity", 100)
  rule_group                 = lookup(each.value, "rule_group", {})
  rules                      = lookup(each.value, "rules", null)
  create_resource_policy     = lookup(each.value, "create_resource_policy", false)
  resource_policy_actions    = lookup(each.value, "resource_policy_actions", [])
  resource_policy_principals = lookup(each.value, "resource_policy_principals", [])
  attach_resource_policy     = lookup(each.value, "attach_resource_policy", false)
  resource_policy            = lookup(each.value, "resource_policy", "")
  ram_resource_associations  = lookup(each.value, "ram_resource_associations", {})
  tags                       = merge(lookup(each.value, "tags", {}), local.tags)
}

resource "aws_cloudwatch_log_group" "logs" {
  depends_on        = [module.vpc]
  count             = local.network_firewall_enabled && local.create_logging_configuration ? 1 : 0
  name              = "${var.cluster.name}-${var.instance_name}-nf-logs"
  retention_in_days = lookup(local.advanced_network_firewall, "cloudwatch_rentention_in_days", 7)
  tags              = local.tags
}

resource "aws_s3_bucket" "network_firewall_logs" {
  depends_on    = [module.vpc]
  count         = local.network_firewall_enabled && local.create_logging_configuration ? 1 : 0
  bucket        = length("${var.cluster.name}-${var.instance_name}-nf-logs-${local.account_id}") > 63 ? md5("${var.cluster.name}-${var.instance_name}-nf-logs-${local.account_id}") : "${var.cluster.name}-${var.instance_name}-nf-logs-${local.account_id}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_policy" "network_firewall_logs" {
  depends_on = [module.vpc]
  count      = local.network_firewall_enabled && local.create_logging_configuration ? 1 : 0
  bucket     = aws_s3_bucket.network_firewall_logs.0.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:PutObject"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.cluster.awsRegion}:${local.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.network_firewall_logs.0.arn}/${var.instance_name}/AWSLogs/${local.account_id}/*"
        Sid      = "AWSLogDeliveryWrite"
      },
      {
        Action = "s3:GetBucketAcl"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.cluster.awsRegion}:${local.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Resource = aws_s3_bucket.network_firewall_logs.0.arn
        Sid      = "AWSLogDeliveryAclCheck"
      },
    ]
  })
}

# Get internet gateway
data "aws_internet_gateway" "default" {
  depends_on = [module.vpc]
  count      = local.network_firewall_enabled ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [module.vpc.vpc_details.vpc_id]
  }
}

data "aws_nat_gateway" "nat_gw" {
  depends_on = [module.vpc]
  count      = local.network_firewall_enabled && local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : 0
  state      = "available"
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_details.vpc_id]
  }
  filter {
    name   = "subnet-id"
    values = [element(module.vpc.vpc_details.public_subnets, count.index)]
  }
}

# Data source for existing NAT gateways provided by user
data "aws_nat_gateway" "existing_nat_gw" {
  count = local.network_firewall_enabled && local.use_existing_nat_gateways ? length(local.existing_nat_gateway_ids) : 0
  id    = local.existing_nat_gateway_ids[count.index]
}

# private subnets to route to nat gateway
resource "aws_route" "private_nat_gateway" {
  depends_on = [module.vpc]
  count      = local.network_firewall_enabled ? (local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : length(local.existing_nat_gateway_ids)) : 0

  route_table_id         = element(module.vpc.vpc_details.private_route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.should_create_nat_gateways ? data.aws_nat_gateway.nat_gw[count.index].id : data.aws_nat_gateway.existing_nat_gw[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "public" {
  count  = local.network_firewall_enabled ? (local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : length(local.existing_nat_gateway_ids)) : 0
  vpc_id = module.vpc.vpc_details.vpc_id

  tags = merge(
    local.tags,
    {
      Name = (local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : length(local.existing_nat_gateway_ids)) > 1 ? "${var.cluster.name}-public-route-table-${var.cluster.azs[count.index]}" : "${var.cluster.name}-public"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  depends_on = [module.vpc, module.network_firewall]
  count      = local.network_firewall_enabled ? (local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : length(local.existing_nat_gateway_ids)) : 0

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  vpc_endpoint_id = [
    for s in module.network_firewall.0.status[0].sync_states :
    s if s.availability_zone == var.cluster.azs[count.index]
  ][0].attachment[0].endpoint_id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  for_each = local.network_firewall_enabled ? {
    for item in flatten([
      for az_index, az in var.cluster.azs : [
        for subnet in module.vpc.vpc_details.az_public_subnets[az] : {
          subnet_id      = subnet
          route_table_id = length(aws_route_table.public) == 1 ? aws_route_table.public[0].id : aws_route_table.public[az_index].id
        }
      ]
    ]) : item.subnet_id => item
  } : {}

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

# Firewall route and rta with subnet creation
resource "aws_subnet" "firewall_subnets" {
  depends_on              = [module.vpc]
  count                   = local.network_firewall_enabled ? length(local.firewall_subnets) : 0
  vpc_id                  = module.vpc.vpc_details.vpc_id
  cidr_block              = local.firewall_subnets[count.index]
  availability_zone       = var.cluster.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    {
      Name = format("${var.cluster.name}-firewall-subnet-${var.cluster.azs[count.index]}")
    }
  )
}

resource "aws_route_table_association" "firewall-rta" {
  depends_on     = [module.vpc]
  count          = local.network_firewall_enabled ? length(local.firewall_subnets) : 0
  subnet_id      = aws_subnet.firewall_subnets[count.index].id
  route_table_id = element(aws_route_table.firewall-rt[*].id, count.index)
}

# firewall subnets to route to internet gateway
resource "aws_route" "firewall_route" {
  depends_on             = [module.vpc]
  count                  = local.network_firewall_enabled ? (local.should_create_nat_gateways ? length(module.vpc.vpc_details.nat_gateway_ips) : length(local.existing_nat_gateway_ids)) : 0
  route_table_id         = aws_route_table.firewall-rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.default.0.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "firewall-rt" {
  depends_on = [module.vpc]
  count      = local.network_firewall_enabled ? (local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : length(local.existing_nat_gateway_ids)) : 0
  vpc_id     = module.vpc.vpc_details.vpc_id
  tags = merge(
    local.tags,
    {
      Name = (local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : length(local.existing_nat_gateway_ids)) > 1 ? "${var.cluster.name}-firewall-${var.cluster.azs[count.index]}" : "${var.cluster.name}-firewall"
    }
  )
}

resource "aws_route_table" "igw-rt" {
  depends_on = [module.vpc]
  count      = local.network_firewall_enabled ? 1 : 0
  vpc_id     = module.vpc.vpc_details.vpc_id
  tags = merge(
    local.tags,
    {
      Name = "${var.cluster.name}-igw-route-table"
    }
  )
}

# route table association for igw
resource "aws_route_table_association" "igw-rta" {
  depends_on     = [module.vpc]
  count          = local.network_firewall_enabled ? 1 : 0
  gateway_id     = data.aws_internet_gateway.default.0.id
  route_table_id = aws_route_table.igw-rt.0.id
}

resource "aws_route" "igw_public_firewall_route" {
  depends_on             = [module.vpc,module.network_firewall]
  count                  = local.network_firewall_enabled ? length(module.vpc.vpc_details.az_public_subnets_cidrs["${var.cluster.azs[0]}"]) : 0
  route_table_id         = aws_route_table.igw-rt.0.id
  destination_cidr_block = module.vpc.vpc_details.az_public_subnets_cidrs["${var.cluster.azs[0]}"][count.index]
  vpc_endpoint_id        = one([for s in module.network_firewall.0.status[0].sync_states : s.attachment[0].endpoint_id if s.availability_zone == var.cluster.azs[0]])

  timeouts {
    create = "5m"
  }
}

# igw to public subnets to route to firewall endpoint for multi az
resource "aws_route" "igw_public_firewall_route_multi_az" {
  depends_on             = [module.vpc,module.network_firewall]
  count                  = local.network_firewall_enabled ? length(module.vpc.vpc_details.az_public_subnets_cidrs["${var.cluster.azs[1]}"]) : 0
  route_table_id         = aws_route_table.igw-rt.0.id
  destination_cidr_block = module.vpc.vpc_details.az_public_subnets_cidrs["${var.cluster.azs[1]}"][count.index]
  vpc_endpoint_id        = (local.should_create_nat_gateways ? module.vpc.vpc_details.nat_gateway_count : length(local.existing_nat_gateway_ids)) > 1 ? one([for s in module.network_firewall.0.status[0].sync_states : s.attachment[0].endpoint_id if s.availability_zone == var.cluster.azs[1]]) : (module.network_firewall.0.status[0].sync_states.sync_states[*].attachment[0].endpoint_id)[0]

  timeouts {
    create = "5m"
  }
}
