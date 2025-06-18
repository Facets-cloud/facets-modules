locals {
  output_interfaces = {}
  output_attributes = {
    project         = local.project
    service_account = local.service_account
    region          = local.region
  }
}
