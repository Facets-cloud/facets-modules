# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    "legacy_outputs" = module.legacy_vpc.legacy_attributes
    secrets          = ["legacy_outputs"]
  }
}
