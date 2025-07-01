module "vpc" {
  source = "./vpc"
  cluster = var.cluster
  cc_metadata = var.cc_metadata
  settings  = var.settings
  instance  = var.instance

  # NAT Gateway configuration
  use_existing_nat_gateways = var.use_existing_nat_gateways
  existing_nat_gateway_ids  = var.existing_nat_gateway_ids
}
