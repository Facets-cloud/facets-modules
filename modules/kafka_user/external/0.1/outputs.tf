locals {
  output_interfaces = {
  }
  output_attributes = {
    username = lookup(local.spec, "username", "")
    password = lookup(local.spec, "password", "")
  }
}
