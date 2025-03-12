locals {
  spec            = var.instance.spec
  advanced        = lookup(var.instance, "advanced", {})
  bus_name        = lookup(local.spec, "name", module.name.name)
  additional_tags = lookup(local.advanced, "additional_tags", {})
}

resource "aws_cloudwatch_event_bus" "bus" {
  name = local.bus_name
  tags = merge(var.environment.cloud_tags, local.additional_tags)
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_type   = "aws_event_bus"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 20
}