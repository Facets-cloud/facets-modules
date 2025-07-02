locals {
  spec = lookup(var.instance, "spec", {})
  additional_tags = lookup(local.spec, "tags", {})
  private_subnets      = [cidrsubnet(var.cluster.vpcCIDR, 4, 0), cidrsubnet(var.cluster.vpcCIDR, 4, 1), cidrsubnet(var.cluster.vpcCIDR, 4, 2), cidrsubnet(var.cluster.vpcCIDR, 4, 3)]
  public_subnets       = [cidrsubnet(var.cluster.vpcCIDR, 4, 12), cidrsubnet(var.cluster.vpcCIDR, 4, 14), cidrsubnet(var.cluster.vpcCIDR, 4, 15)]
  database_subnets     = [cidrsubnet(var.cluster.vpcCIDR, 4, 4), cidrsubnet(var.cluster.vpcCIDR, 4, 5)]
  gateway_subnet       = [cidrsubnet(var.cluster.vpcCIDR, 4, 6)]
  cache_subnet         = [cidrsubnet(var.cluster.vpcCIDR, 8, 112)]
  fns_subnets          = [cidrsubnet(var.cluster.vpcCIDR, 8, 113)]
  priv_link_svc_subnet = [cidrsubnet(var.cluster.vpcCIDR, 8, 114)]
  public_subnet_map    = { for item in [for k, v in local.public_subnets : { index = k, cidr = v }] : item.index => item }
  private_subnet_map   = { for item in [for k, v in local.private_subnets : { index = k, cidr = v }] : item.index => item }
  database_subnets_map = { for item in [for k, v in local.database_subnets : { index = k, cidr = v }] : item.index => item }
  functions_subnet_map = { for item in [for k, v in local.fns_subnets : { index = k, cidr = v }] : item.index => item }
  priv_link_subnet_map = { for item in [for k, v in local.priv_link_svc_subnet : { index = k, cidr = v }] : item.index => item }
  #gateway_subnet_map = {for item in [for k, v in  local.gateway_subnet : { index = k, cidr = v }]:item.index => item}
  gateway_subnet_map   = {}
  cache_subnet_map     = { for item in [for k, v in local.cache_subnet : { index = k, cidr = v }] : item.index => item }
  is_existing_resource = length(lookup(var.cluster, "resourceGroupName", "")) > 0 && length(lookup(var.cluster, "vnetName", "")) > 0 ? true : false
  resource_group_name  = local.is_existing_resource ? data.azurerm_resource_group.existing_rg[0].name : length(azurerm_resource_group.res_grp) > 0 ? azurerm_resource_group.res_grp[0].name : null
  resource_group_id    = local.is_existing_resource ? data.azurerm_resource_group.existing_rg[0].id : length(azurerm_resource_group.res_grp) > 0 ? azurerm_resource_group.res_grp[0].id : null
  location             = local.is_existing_resource ? data.azurerm_resource_group.existing_rg[0].location : length(azurerm_resource_group.res_grp) > 0 ? azurerm_resource_group.res_grp[0].location : null
  vnet_name            = local.is_existing_resource ? data.azurerm_virtual_network.existing_vnet[0].name : length(azurerm_virtual_network.vnet) > 0 ? azurerm_virtual_network.vnet[0].name : null
  vnet_id              = local.is_existing_resource ? data.azurerm_virtual_network.existing_vnet[0].id : length(azurerm_virtual_network.vnet) > 0 ? azurerm_virtual_network.vnet[0].id : null
  tags = merge(local.additional_tags, {
    facetscontrolplane = split(".", var.cc_metadata.cc_host)[0]
    cluster            = var.cluster.name
    facetsclustername  = var.cluster.name
    facetsclusterid    = var.cluster.id
  })
  concatenated_name = "${var.cluster.stackName}-${var.cluster.name}-${var.instance_name}"
  subnet_name       = length(local.concatenated_name) > 60 ? substr(local.concatenated_name, 0, 60) : local.concatenated_name
  
  # NAT Gateway configuration
  should_create_nat_gateways = var.nat_gateway_type == "create_new"
  should_use_existing_nat    = var.nat_gateway_type == "use_existing"
  nat_gateway_count         = 1  # Always 1 since only one NAT gateway can be attached to subnets
}

data "azurerm_resource_group" "existing_rg" {
  count = local.is_existing_resource ? 1 : 0

  name = var.cluster.resourceGroupName
}

data "azurerm_virtual_network" "existing_vnet" {
  count = local.is_existing_resource ? 1 : 0

  name                = var.cluster.vnetName
  resource_group_name = data.azurerm_resource_group.existing_rg[count.index].name
}

data "azurerm_nat_gateway" "existing_nat_gw" {
  count = local.should_use_existing_nat && var.existing_nat_gateway_name != "" ? 1 : 0
  name  = var.existing_nat_gateway_name
  
  # Logic for resource group selection:
  # - If use_vnet_resource_group is true: use the VNet's resource group automatically
  # - If use_vnet_resource_group is false: use the explicitly provided resource group
  resource_group_name = var.use_vnet_resource_group ? local.resource_group_name : var.existing_nat_gateway_resource_group
}





resource "azurerm_resource_group" "res_grp" {
  count = local.is_existing_resource ? 0 : 1

  name     = "${substr(var.cluster.name, 0, 80 - length(var.instance_name) - 11)}-${var.instance_name}-${var.cluster.clusterCode}"
  location = var.cluster.region
  tags     = local.tags
  lifecycle {
    ignore_changes  = [name]
    prevent_destroy = true
  }
}


resource "azurerm_virtual_network" "vnet" {
  count = local.is_existing_resource ? 0 : 1

  name                = "${substr(var.cluster.name, 0, 54 - length(var.instance_name) - 11)}-${var.instance_name}-${var.cluster.clusterCode}-vnet"
  resource_group_name = azurerm_resource_group.res_grp[0].name
  location            = var.cluster.region
  address_space       = [var.cluster.vpcCIDR]
  tags                = local.tags
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }

}

resource "azurerm_subnet" "private_subnet" {
  for_each             = local.private_subnet_map
  name                 = "${local.subnet_name}-private-subnet-${each.value.index}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage"]
  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }
}

resource "azurerm_subnet" "public_subnet" {
  for_each             = local.public_subnet_map
  name                 = "${local.subnet_name}-public-subnet-${each.value.index}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage"]
  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }

}

resource "azurerm_subnet" "gateway_subnet" {
  for_each             = local.gateway_subnet_map
  name                 = "${local.subnet_name}-gateway-subnet-${each.value.index}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage"]
  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }

}

resource "azurerm_subnet" "cache_subnet" {
  for_each             = local.cache_subnet_map
  name                 = "${local.subnet_name}-cache-subnet-${each.value.index}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage"]
  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }
}

resource "azurerm_subnet" "database_subnets" {
  for_each                              = local.database_subnets_map
  name                                  = "${local.subnet_name}-database_subnets-${each.value.index}"
  resource_group_name                   = local.resource_group_name
  virtual_network_name                  = local.vnet_name
  address_prefixes  = [each.value.cidr]
  service_endpoints = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
  lifecycle {
    ignore_changes = [service_endpoints, delegation, name]
  }
}

resource "azurerm_subnet" "functions_subnets" {
  for_each             = local.functions_subnet_map
  name                 = "${local.subnet_name}-fns_subnets-${each.value.index}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fns"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  lifecycle {
    ignore_changes = [service_endpoints, delegation, name]
  }
}

resource "azurerm_subnet" "private_link_service_subnets" {
  for_each             = local.priv_link_subnet_map
  name                 = "${local.subnet_name}-pls_subnets-${each.value.index}" # pls = private link service
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage"]
  lifecycle {
    ignore_changes = [service_endpoints, name]
  }
}

resource "azurerm_network_security_group" "allow_all_default" {
  name                = "allow_all_${substr(var.cluster.name, 0, 70 - length(var.instance_name) - 11 - 18)}-${var.instance_name}-${var.cluster.clusterCode}-default"
  resource_group_name = local.resource_group_name
  location            = local.location
  tags = merge({
    Terraform = "true"
    cluster   = "${var.cluster.name}"
  }, local.tags)

  security_rule {
    name                       = "allow_all_${substr(var.cluster.name, 0, 70 - length(var.instance_name) - 18)}-${var.instance_name}-default"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.cluster.vpcCIDR
    destination_address_prefix = "*"
    description                = "Allowing connection from within vnet"

  }

  lifecycle {
    ignore_changes = [name]
  }
}


resource "azurerm_public_ip" "nat-ip" {
  count               = local.should_create_nat_gateways ? local.nat_gateway_count : 0
  name                = "${substr(var.cluster.name, 0, 70 - length(var.instance_name) - 11 - 11)}-${var.instance_name}-${var.cluster.clusterCode}-NATGW-ip-${count.index + 1}"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = element(var.cluster.azs, count.index) == "" ? null : [element(var.cluster.azs, count.index)]
  tags                = local.tags

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_nat_gateway" "nat-gw" {
  count               = local.should_create_nat_gateways ? local.nat_gateway_count : 0
  name                = "${substr(var.cluster.name, 0, 70 - length(var.instance_name) - 11 - 8)}-${var.instance_name}-${var.cluster.clusterCode}-NATGW-${count.index + 1}"
  resource_group_name = local.resource_group_name
  location            = local.location
  # public_ip_prefix_ids    = [azurerm_public_ip_prefix.nat-ip-prefix[count.index].id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = element(var.cluster.azs, count.index) == "" ? null : [element(var.cluster.azs, count.index)]
  tags                    = local.tags
  lifecycle {
    ignore_changes = [name]
  }
}

locals {
  # Get the single NAT gateway ID - either from created or existing NAT gateway
  nat_gateway_id = local.should_create_nat_gateways ? (
    length(azurerm_nat_gateway.nat-gw) > 0 ? azurerm_nat_gateway.nat-gw[0].id : null
  ) : (
    length(data.azurerm_nat_gateway.existing_nat_gw) > 0 ? data.azurerm_nat_gateway.existing_nat_gw[0].id : null
  )


}

resource "azurerm_nat_gateway_public_ip_association" "nat-ip-assoc" {
  count                = local.should_create_nat_gateways ? local.nat_gateway_count : 0
  nat_gateway_id       = azurerm_nat_gateway.nat-gw[count.index].id
  public_ip_address_id = azurerm_public_ip.nat-ip[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "nat-subnet-assoc" {
  for_each = (local.should_create_nat_gateways || local.should_use_existing_nat) ? local.private_subnet_map : {}
  
  subnet_id      = azurerm_subnet.private_subnet[each.key].id
  nat_gateway_id = local.nat_gateway_id
}

resource "azurerm_subnet_nat_gateway_association" "nat-subnet-func-assoc" {
  for_each = (local.should_create_nat_gateways || local.should_use_existing_nat) ? local.functions_subnet_map : {}
  
  subnet_id      = azurerm_subnet.functions_subnets[each.key].id
  nat_gateway_id = local.nat_gateway_id
}
