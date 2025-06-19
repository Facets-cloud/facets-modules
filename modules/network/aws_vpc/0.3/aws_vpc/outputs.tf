output "legacy_attributes" {
  value = {
    vpc_details = merge(
      module.vpc.vpc_details, local.network_firewall_enabled ? {
        public_route_table_ids = aws_route_table.public.*.id
      } : {}
    )
  }
}
