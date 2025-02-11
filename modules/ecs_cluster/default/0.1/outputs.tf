locals {
  output_attributes = {
    cluster_arn  = module.ecs.arn
    cluster_name = module.ecs.name
  }
  output_interfaces = {}
}