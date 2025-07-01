# Define your terraform resources here
module "legacy_vpc" {
  source      = "../../3_utility/legacy_azure_vpc"
  cluster     = local.cluster
  cc_metadata = var.cc_metadata
  settings    = local.settings
  instance    = var.instance

  # NAT Gateway configuration
  use_existing_nat_gateways = lookup(local.spec, "use_existing_nat_gateways", false)
  existing_nat_gateway_ids  = lookup(local.spec, "existing_nat_gateway_ids", [])
}
