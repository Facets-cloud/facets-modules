locals {
  output_attributes = {
    username = local.user_name
    password = local.user_password
    secrets  = ["password"]
  }
  output_interfaces = {}
}

output "username" {
  value = local.user_name
}

output "password" {
  value     = local.user_password
  sensitive = true
}
