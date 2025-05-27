# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    "issuers" = [for i in local.environments : i.name]
  }
}
