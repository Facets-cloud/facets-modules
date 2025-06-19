locals {
  spec                      = lookup(var.instance, "spec", {})
  advanced                  = lookup(var.instance, "advanced", {})
  advanced_network          = lookup(local.advanced, "network", {})
  advanced_network_firewall = lookup(local.advanced_network, "network_firewall", {})
  network_firewall_enabled  = lookup(local.advanced_network_firewall, "enabled", false)
  azs                       = [var.cluster.azs[0], var.cluster.azs[1]]
  multi_azs                 = var.settings.MULTI_AZ ? local.azs : [var.cluster.azs[0]]
  account_id                = data.aws_caller_identity.current.account_id
  rule_groups               = lookup(local.advanced_network_firewall, "rule_groups", {})
  firewall_subnets          = [cidrsubnet(var.cluster.vpcCIDR, 4, 8), cidrsubnet(var.cluster.vpcCIDR, 4, 9)]
  public_subnets_cidr       = module.vpc.vpc_details.public_subnets_cidr_blocks
  public_subnets_ids        = module.vpc.vpc_details.public_subnets
  tags = {
    facetscontrolplane = split(".", var.cc_metadata.cc_host)[0]
    cluster            = var.cluster.name
    facetsclustername  = var.cluster.name
    facetsclusterid    = var.cluster.id
  }
  create_logging_configuration              = lookup(local.advanced_network_firewall, "create_logging_configuration", false)
  alert_logging_configuration_destination   = lookup(local.advanced_network_firewall, "alert_logging_configuration_destination", "cloudwatch")
  enable_s3_flowlog_configuration           = lookup(local.advanced_network_firewall, "enable_s3_flowlog_configuration", false)
  enable_cloud_watch_flow_log_configuration = lookup(local.advanced_network_firewall, "enable_cloud_watch_flow_log_configuration", false)
  
  # NAT Gateway configuration
  use_existing_nat_gateways = var.use_existing_nat_gateways
  existing_nat_gateway_ids  = var.existing_nat_gateway_ids
  should_create_nat_gateways = !local.use_existing_nat_gateways
}
