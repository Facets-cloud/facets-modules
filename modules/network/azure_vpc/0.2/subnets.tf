#########################################################################
# Subnet Resources                                                      #
#########################################################################

# Public Subnets
resource "azurerm_subnet" "public" {
  for_each = var.instance.spec.public_subnets.count_per_az > 0 ? {
    for subnet in local.public_subnets :
    "${subnet.az}-${subnet.subnet_index}" => subnet
  } : {}

  name                 = "${local.name_prefix}-public-${each.value.az}-${each.value.subnet_index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr_block]
  service_endpoints    = ["Microsoft.Storage"]

  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }
}

# Private Subnets
resource "azurerm_subnet" "private" {
  for_each = {
    for subnet in local.private_subnets :
    "${subnet.az}-${subnet.subnet_index}" => subnet
  }

  name                 = "${local.name_prefix}-private-${each.value.az}-${each.value.subnet_index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr_block]
  service_endpoints    = ["Microsoft.Storage"]

  # Delegate subnet to specific services if needed
  dynamic "delegation" {
    for_each = var.instance.spec.enable_aks ? [1] : []
    content {
      name = "aks-delegation"
      service_delegation {
        name = "Microsoft.ContainerService/managedClusters"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
        ]
      }
    }
  }

  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }
}

# Database Subnets
resource "azurerm_subnet" "database" {
  for_each = {
    for subnet in local.database_subnets :
    "${subnet.az}-${subnet.subnet_index}" => subnet
  }

  name                 = "${local.name_prefix}-database-${each.value.az}-${each.value.subnet_index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr_block]
  service_endpoints    = ["Microsoft.Storage"]

  # Configure private endpoint network policies
  private_endpoint_network_policies = "Disabled"

  # Delegate to SQL services
  delegation {
    name = "sql-delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }

  lifecycle {
    ignore_changes = [service_endpoints, delegation, name]
  }
}

# Gateway Subnets (for VPN/ExpressRoute gateways)
resource "azurerm_subnet" "gateway" {
  for_each = {
    for subnet in local.gateway_subnets :
    "${subnet.subnet_index}" => subnet
  }

  name                 = "${local.name_prefix}-gateway-subnet-${each.value.subnet_index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr_block]
  service_endpoints    = ["Microsoft.Storage"]

  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }
}

# Cache Subnets (for Redis and other caching services)
resource "azurerm_subnet" "cache" {
  for_each = {
    for subnet in local.cache_subnets :
    "${subnet.subnet_index}" => subnet
  }

  name                 = "${local.name_prefix}-cache-subnet-${each.value.subnet_index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr_block]
  service_endpoints    = ["Microsoft.Storage"]

  lifecycle {
    ignore_changes = [delegation, service_endpoints, name]
  }
}

# Functions Subnets (dedicated for Azure Functions)
resource "azurerm_subnet" "functions" {
  for_each = {
    for subnet in local.functions_subnets :
    "${subnet.subnet_index}" => subnet
  }

  name                 = "${local.name_prefix}-functions-subnet-${each.value.subnet_index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr_block]
  service_endpoints    = ["Microsoft.Storage"]

  # Configure private endpoint network policies  
  private_endpoint_network_policies = "Disabled"

  # Delegate to Azure Functions
  delegation {
    name = "functions-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  lifecycle {
    ignore_changes = [service_endpoints, delegation, name]
  }
}

# Private Link Service Subnets
resource "azurerm_subnet" "private_link_service" {
  for_each = {
    for subnet in local.private_link_service_subnets :
    "${subnet.subnet_index}" => subnet
  }

  name                 = "${local.name_prefix}-pls-subnet-${each.value.subnet_index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr_block]
  service_endpoints    = ["Microsoft.Storage"]

  # Configure private link service network policies (disabled for Private Link Service)
  private_link_service_network_policies_enabled = false

  lifecycle {
    ignore_changes = [service_endpoints, name]
  }
}
