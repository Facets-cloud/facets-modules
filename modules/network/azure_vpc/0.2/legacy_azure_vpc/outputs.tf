output "legacy_attributes" {
  value = {
    vpc_details = module.vpc.vpc_details
    azure_cloud = {
      location          = var.cluster.region
      resource_group    = module.vpc.resource_group
      resource_group_id = module.vpc.resource_group_id
      subscriptionId    = "/subscriptions/${var.cluster.subscriptionId}"
      tenantId          = var.cluster.tenantId
    }
  }
}
