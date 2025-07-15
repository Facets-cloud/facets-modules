locals {
  output_attributes = {}
  output_interfaces = {}
}

output "uid" {
  value       = random_string.uid.result
  description = "The random string generated for dashboard"
}
