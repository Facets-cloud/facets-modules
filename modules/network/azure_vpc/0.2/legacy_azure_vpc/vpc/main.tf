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
  resource_group_name  = local.is_existing_resource ? data.azurerm_resource_group.existing_rg[0].name : length(azurerm_resource_group.res_grp) > 0 ? azurerm_resource_group.res_grp.name : null
  location             = local.is_existing_resource ? data.azurerm_resource_group.existing_rg[0].location : length(azurerm_resource_group.res_grp) > 0 ? azurerm_resource_group.res_grp.location : null
  vnet_name            = local.is_existing_resource ? data.azurerm_virtual_network.existing_vnet[0].name : length(azurerm_virtual_network.vnet) > 0 ? azurerm_virtual_network.vnet[0].name : null
  vnet_id              = local.is_existing_resource ? data.azurerm_virtual_network.existing_vnet[0].id : length(azurerm_virtual_network.vnet) > 0 ? azurerm_virtual_network.vnet[0].id : null
  tags = merge(local.additional_tags, {
    facetscontrolplane = split(".", var.cc_metadata.cc_host)[0]
    cluster            = var.cluster.name
    facetsclustername  = var.cluster.name
    facetsclusterid    = var.cluster.id
  })
  concatenated_name = "${var.cluster.stackName}-${var.cluster.name}"
  subnet_name       = length(local.concatenated_name) > 60 ? substr(local.concatenated_name, 0, 60) : local.concatenated_name
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

resource "azurerm_resource_group" "res_grp" {

  name     = "${substr(var.cluster.name, 0, 90 - 11)}-${var.cluster.clusterCode}"
  location = var.cluster.region
  tags     = local.tags
  lifecycle {
    ignore_changes  = [name]
    prevent_destroy = true
  }
}


resource "azurerm_virtual_network" "vnet" {
  count = local.is_existing_resource ? 0 : 1

  name                = "${substr(var.cluster.name, 0, 64 - 11 - 5)}-${var.cluster.clusterCode}-vnet"
  resource_group_name = azurerm_resource_group.res_grp.name
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
  for_each                                      = local.database_subnets_map
  name                                          = "${local.subnet_name}-database_subnets-${each.value.index}"
  resource_group_name                           = local.resource_group_name
  virtual_network_name                          = local.vnet_name
  address_prefixes                              = [each.value.cidr]
  service_endpoints                             = ["Microsoft.Storage"]
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
  for_each                                      = local.functions_subnet_map
  name                                          = "${local.subnet_name}-fns_subnets-${each.value.index}"
  resource_group_name                           = local.resource_group_name
  virtual_network_name                          = local.vnet_name
  address_prefixes                              = [each.value.cidr]
  service_endpoints                             = ["Microsoft.Storage"]
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
  for_each                                     = local.priv_link_subnet_map
  name                                         = "${local.subnet_name}-pls_subnets-${each.value.index}" # pls = private link service
  resource_group_name                          = local.resource_group_name
  virtual_network_name                         = local.vnet_name
  address_prefixes                             = [each.value.cidr]
  private_link_service_network_policies_enabled = false # This flag is why we need a subnet for private link service
  service_endpoints                            = ["Microsoft.Storage"]
  lifecycle {
    ignore_changes = [service_endpoints, name]
  }
}

resource "azurerm_network_security_group" "allow_all_default" {
  name                = "allow_all_${substr(var.cluster.name, 0, 80 - 11 - 18)}-${var.cluster.clusterCode}-default"
  resource_group_name = azurerm_resource_group.res_grp.name
  location            = var.cluster.region
  tags = merge({
    Terraform = "true"
    cluster   = "${var.cluster.name}"
  }, local.tags)

  security_rule {
    name                       = "allow_all_${substr(var.cluster.name, 0, 80 - 18)}-default"
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
  count               = var.use_existing_nat_gateways ? 0 : 1
  name                = "${substr(var.cluster.name, 0, 80 - 11 - 11)}-${var.cluster.clusterCode}-NATGW-ip-${count.index + 1}"
  resource_group_name = azurerm_resource_group.res_grp.name
  location            = var.cluster.region
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = element(var.cluster.azs, count.index) == "" ? null : [element(var.cluster.azs, count.index)]
  tags                = local.tags

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_nat_gateway" "nat-gw" {
  count               = var.use_existing_nat_gateways ? 0 : 1
  name                = "${substr(var.cluster.name, 0, 80 - 11 - 8)}-${var.cluster.clusterCode}-NATGW-${count.index + 1}"
  resource_group_name = azurerm_resource_group.res_grp.name
  location            = var.cluster.region
  # public_ip_prefix_ids    = [azurerm_public_ip_prefix.nat-ip-prefix[count.index].id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = element(var.cluster.azs, count.index) == "" ? null : [element(var.cluster.azs, count.index)]
  tags                    = local.tags
  lifecycle {
    ignore_changes = [name]
  }
}

# Data source to get existing NAT gateways when using existing ones
data "azurerm_nat_gateway" "existing_nat_gw" {
  count               = var.use_existing_nat_gateways ? length(var.existing_nat_gateway_ids) : 0
  name                = element(split("/", var.existing_nat_gateway_ids[count.index]), length(split("/", var.existing_nat_gateway_ids[count.index])) - 1)
  resource_group_name = element(split("/", var.existing_nat_gateway_ids[count.index]), 4)
}

locals {
  # Combine created and existing NAT gateway IDs
  nat_gateway_ids = var.use_existing_nat_gateways ? var.existing_nat_gateway_ids : azurerm_nat_gateway.nat-gw.*.id

  nat_private_subnet_map = {
    for i, j in keys(azurerm_subnet.private_subnet) :
    i => { subnetid = azurerm_subnet.private_subnet[j].id, natid = element(local.nat_gateway_ids, i)
    }
  }

  nat_functions_subnet_map = {
    for i, j in keys(azurerm_subnet.functions_subnets) :
    i => { subnetid = azurerm_subnet.functions_subnets[j].id, natid = element(local.nat_gateway_ids, i)
    }
  }

}

resource "azurerm_nat_gateway_public_ip_association" "nat-ip-assoc" {
  count                = var.use_existing_nat_gateways ? 0 : 1
  nat_gateway_id       = azurerm_nat_gateway.nat-gw[count.index].id
  public_ip_address_id = azurerm_public_ip.nat-ip[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "nat-subnet-assoc" {
  for_each       = local.nat_private_subnet_map
  subnet_id      = each.value.subnetid
  nat_gateway_id = each.value.natid
}

resource "azurerm_subnet_nat_gateway_association" "nat-subnet-func-assoc" {
  for_each       = local.nat_functions_subnet_map
  subnet_id      = each.value.subnetid
  nat_gateway_id = each.value.natid
}
