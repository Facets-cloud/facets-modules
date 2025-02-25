locals {
  output_attributes = {
    username = local.role_name
    password = local.postgres_user_password
    secrets  = ["password"]
  }
  output_interfaces = {}
}

output "username" {
  value = local.role_name
}

output "password" {
  value = local.postgres_user_password
}
