locals {
  output_attributes = {
    "legacy_outputs" = local.vpc_details
    secrets          = ["legacy_outputs"]
  }
  output_interfaces = {
  }
}
