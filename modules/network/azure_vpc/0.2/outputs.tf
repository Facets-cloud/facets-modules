# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    "legacy_outputs" = module.vpc.vpc_details
    secrets          = ["legacy_outputs"]
  }
}
