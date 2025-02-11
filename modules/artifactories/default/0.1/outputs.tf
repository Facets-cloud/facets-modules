locals {
  output_interfaces = {}
  output_attributes = {
    registry_secrets_list   = local.registry_secrets_list
    registry_secret_objects = local.registry_secret_objects
  }
}
