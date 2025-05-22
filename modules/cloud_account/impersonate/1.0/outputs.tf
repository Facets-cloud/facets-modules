locals {
  output_interfaces = {}
  output_attributes = {
    access_token = data.google_service_account_access_token.default.access_token
  }
}