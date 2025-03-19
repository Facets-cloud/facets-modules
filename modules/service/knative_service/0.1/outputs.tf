locals {
  output_attributes = {
    namespace = var.environment.namespace
    resource_type = local.resource_labels.resourceType
    resource_name = local.resource_labels.resourceName
    service_name = local.resource_labels.resourceName
    image  = local.image_id
  }
  output_interfaces = {
    port = local.ports_mapping
  }
}
