
output "vpc_details" {
  value = {
    vpc_id = local.vnet_id
    #picking private subnets with index 2 and 3.
    private_subnets = length(azurerm_subnet.private_subnet) > 0 ? slice(values({
      for i in keys(azurerm_subnet.private_subnet) :
      i => azurerm_subnet.private_subnet[i].id
    }), 0, length(azurerm_subnet.private_subnet)) : null
    #default_subnet_id = try(module.vnet.vnet_subnets[0], null)
    default_security_group_id    = azurerm_network_security_group.allow_all_default.id
    cluster_azresource_group     = azurerm_resource_group.res_grp.name
    cluster_azresource_group_id  = azurerm_resource_group.res_grp.id
    existing_azresource_group    = local.is_existing_resource ? data.azurerm_resource_group.existing_rg[0].name : ""
    existing_azresource_group_id = local.is_existing_resource ? data.azurerm_resource_group.existing_rg[0].id : ""
    #picking private subnets with index 0 and 1.
    k8s_subnets = length(azurerm_subnet.private_subnet) > 0 ? slice(values({
      for i in keys(azurerm_subnet.private_subnet) :
      i => azurerm_subnet.private_subnet[i].id
    }), 0, length(azurerm_subnet.private_subnet)) : null
    #picking public subnets with index 0 and 1.
    public_subnets = length(azurerm_subnet.public_subnet) > 0 ? slice(values({
      for i in keys(azurerm_subnet.public_subnet) :
      i => azurerm_subnet.public_subnet[i].id
    }), 0, length(azurerm_subnet.public_subnet)) : null
    database_subnets = length(azurerm_subnet.database_subnets) > 0 ? slice(values({
      for i in keys(azurerm_subnet.database_subnets) :
      i => azurerm_subnet.database_subnets[i].id
    }), 0, length(azurerm_subnet.database_subnets)) : null
    functions_subnets = length(azurerm_subnet.functions_subnets) > 0 ? slice(values({
      for i in keys(azurerm_subnet.functions_subnets) :
      i => azurerm_subnet.functions_subnets[i].id
    }), 0, length(azurerm_subnet.functions_subnets)) : null
    gateway_subnets = length(azurerm_subnet.gateway_subnet) > 0 ? values({
      for i in keys(azurerm_subnet.gateway_subnet) :
      i => azurerm_subnet.gateway_subnet[i].id
    }) : null
    cache_subnets = length(azurerm_subnet.cache_subnet) > 0 ? slice(values({
      for i in keys(azurerm_subnet.cache_subnet) :
      i => azurerm_subnet.cache_subnet[i].id
    }), 0, length(azurerm_subnet.cache_subnet)) : null
    private_link_service_subnets = length(azurerm_subnet.private_link_service_subnets) > 0 ? slice(values({
      for i in keys(azurerm_subnet.private_link_service_subnets) :
      i => azurerm_subnet.private_link_service_subnets[i].id
    }), 0, length(azurerm_subnet.private_link_service_subnets)) : null
    azs = var.settings.MULTI_AZ ? var.cluster.azs : [var.cluster.azs[0]]
    vpc_cidr = var.cluster.vpcCIDR
    //public_route_table_ids = module.vpc.public_route_table_ids
    //private_route_table_ids = zipmap(local.private_subnets, module.vpc.private_route_table_ids)
    //default_private_route_table_id = try(module.vpc.private_route_table_ids[0], null)
  }
}

output "resource_group" {
  value = azurerm_resource_group.res_grp.name
}

output "resource_group_id" {
  value = azurerm_resource_group.res_grp.id
}

