locals {
  output_attributes = {
    username = local.role_name
    password = lookup(local.postgres_user,"user_password",module.user_password.result)
    secrets  = ["password"]
  }
  output_interfaces = {}
}

output "username" {
  value = local.role_name
}

output "password" {
  value = lookup(local.postgres_user,"user_password",module.user_password.result)
}
