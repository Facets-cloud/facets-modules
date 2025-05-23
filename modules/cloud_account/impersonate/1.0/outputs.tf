locals {
  output_interfaces = {}
  output_attributes = {
    project      = lookup(local.spec, "project", null)
    access_token = data.google_service_account_access_token.default.access_token
  }
}