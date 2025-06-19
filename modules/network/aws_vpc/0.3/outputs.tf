output "legacy_attributes" {
  value = {
    vpc_details = merge(
      module.vpc.vpc_details, local.network_firewall_enabled ? {
        public_route_table_ids = aws_route_table.public.*.id
      } : {}
    )
  }
}


# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    "legacy_outputs" = module.legacy_vpc.legacy_attributes
    secrets          = ["legacy_outputs"]
  }
}
