locals {
  output_interfaces = {
  }
  output_attributes = {
    username = lookup(local.spec, "username", "")
    password = sensitive(lookup(local.spec, "password", ""))
  }
}
