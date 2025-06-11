locals {
  output_attributes = {}
  output_interfaces = {}
}

output "alert-group-output" {
  value = {
    "alert-group-output" = local.userspecified_rules
  }
}
