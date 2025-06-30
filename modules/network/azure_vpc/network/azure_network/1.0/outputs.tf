locals {
  output_attributes = {
    resource_group_id                   = azurerm_resource_group.main.id
    resource_group_name                 = azurerm_resource_group.main.name
    vnet_id                             = azurerm_virtual_network.main.id
    vnet_name                           = azurerm_virtual_network.main.name
    vnet_cidr_block                     = var.instance.spec.vnet_cidr
    location                            = azurerm_resource_group.main.location
    availability_zones                  = var.instance.spec.availability_zones
    nat_gateway_ids                     = values(azurerm_nat_gateway.main)[*].id
    nat_gateway_public_ip_ids           = values(azurerm_public_ip.nat_gateway)[*].id
    public_subnet_ids                   = values(azurerm_subnet.public)[*].id
    private_subnet_ids                  = values(azurerm_subnet.private)[*].id
    database_subnet_ids                 = values(azurerm_subnet.database)[*].id
    gateway_subnet_ids                  = values(azurerm_subnet.gateway)[*].id
    cache_subnet_ids                    = values(azurerm_subnet.cache)[*].id
    functions_subnet_ids                = values(azurerm_subnet.functions)[*].id
    private_link_service_subnet_ids     = values(azurerm_subnet.private_link_service)[*].id
    default_security_group_id           = azurerm_network_security_group.allow_all_default.id
    private_endpoints_security_group_id = try(azurerm_network_security_group.vpc_endpoints[0].id, null)
    storage_private_endpoint_id         = try(azurerm_private_endpoint.storage[0].id, null)
    storage_account_id                  = try(azurerm_storage_account.example[0].id, null)
  }
  output_interfaces = {
  }
}