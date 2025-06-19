locals {
  spec     = lookup(var.instance, "spec")
  advanced = lookup(var.instance, "advanced", {})
  settings = merge(var.settings.CLUSTER, { "MULTI_AZ" : lookup(local.spec, "enable_multi_az", var.settings.CLUSTER.MULTI_AZ) })
  cluster  = merge(var.cluster, { "providedVPCId" : lookup(local.spec, "choose_vpc_type", "create_new_vpc") == "use_existing_vpc" ? lookup(local.spec, "existing_vpc_id", lookup(var.cluster, "providedVPCId", null)) : lookup(var.cluster, "providedVPCId", null) }, { "vpcCIDR" : lookup(local.spec, "vpc_cidr", lookup(var.cluster, "vpcCIDR", null)) }, { "azs" : lookup(local.spec, "azs", lookup(var.cluster, "azs", null)) })

  # VPC creation logic  
  create_new_vpc = lookup(local.spec, "choose_vpc_type", "create_new_vpc") == "create_new_vpc"

  # NAT Gateway logic
  create_new_nat_gateways = !lookup(local.spec, "use_existing_nat_gateways", false)
}
