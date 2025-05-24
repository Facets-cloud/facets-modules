locals {
  output_interfaces = {}
  output_attributes = {
    project         = lookup(local.spec, "project", null)
    service_account = lookup(local.spec, "service_account", null)
  }
}
