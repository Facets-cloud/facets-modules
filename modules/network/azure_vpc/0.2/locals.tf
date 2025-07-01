# Define your locals here
locals {
  spec     = lookup(var.instance, "spec")
  advanced = lookup(var.instance, "advanced", {})
  settings = merge(var.settings.CLUSTER, { "MULTI_AZ" : lookup(local.spec, "enable_multi_az", var.settings.CLUSTER.MULTI_AZ) })
  cluster = merge(var.cluster,
    { "vpcCIDR" : lookup(local.spec, "vpc_cidr", lookup(var.cluster, "vpcCIDR", null)) },
    { "resourceGroupName" : lookup(local.spec, "choose_vpc_type", "create_new_vpc") == "use_existing_vpc" ? lookup(local.spec, "resource_group_name", lookup(var.cluster, "resourceGroupName", "")) : lookup(var.cluster, "resourceGroupName", "") },
    { "vnetName" : lookup(local.spec, "choose_vpc_type", "create_new_vpc") == "use_existing_vpc" ? lookup(local.spec, "vnet_name", lookup(var.cluster, "vnetName", "")) : lookup(var.cluster, "vnetName", "") },
    { "azs" : lookup(local.spec, "azs", lookup(var.cluster, "azs", null)) },
    { "region": lookup(local.spec, "region", lookup(var.cluster, "region", null)) }
  )
}