locals {
  output_attributes = {}
  output_interfaces = {
    cluster = {
      endpoint          = lookup(local.spec, "endpoint", "")
      username          = lookup(local.spec, "username", "")
      password          = sensitive(lookup(local.spec, "password", ""))
      connection_string = sensitive(lookup(local.spec, "connection_string", ""))
      secrets           = ["connection_string", "password"]
    }
  }
}