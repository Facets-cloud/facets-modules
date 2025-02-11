locals {
  output_attributes = {
    username = lookup(local.mysql_user, "user_name", module.username.name)
    password = lookup(local.mysql_user, "user_password", module.user_password.result)
    secrets  = ["password"]
  }
  output_interfaces = {}
}
