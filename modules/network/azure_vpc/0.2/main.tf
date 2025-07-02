# Define your terraform resources here
module "vpc" {
  source        = "./vpc"
  cluster       = local.cluster
  cc_metadata   = var.cc_metadata
  settings      = local.settings
  instance      = var.instance
  instance_name = var.instance_name

  # NAT Gateway configuration
  nat_gateway_type                    = lookup(local.spec, "nat_gateway_type", "create_new")
  existing_nat_gateway_name           = lookup(local.spec, "existing_nat_gateway_name", "")
  use_vnet_resource_group             = lookup(local.spec, "use_vnet_resource_group", true)
  existing_nat_gateway_resource_group = lookup(local.spec, "existing_nat_gateway_resource_group", "")
}
