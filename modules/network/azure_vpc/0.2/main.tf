#########################################################################
# Terraform Module Structure                                            #
#                                                                       #
# ── Guidance for Code Generators / AI Tools ─────────────────────────  #
#                                                                       #
# • Keep this main.tf file **intentionally empty**.                     #
#   It serves only as the module's entry point.                         #
#                                                                       #
# • Create additional *.tf files that are **logically grouped**         #
#   according to the functionality and resources of the module.         #
#                                                                       #
# • Group related resources, data sources, locals, variables, and       #
#   outputs into separate files to improve clarity and maintainability. #
#                                                                       #
# • Choose file names that clearly reflect the purpose of the contents. #
#                                                                       #
# • Add new files as needed when new functionality areas are introduced,#
#   instead of expanding existing files indefinitely.                   #
#                                                                       #
# This ensures modules stay clean, scalable, and easy to navigate.      #
#########################################################################

# Local values for calculations
locals {
  # Private endpoint DNS zone mappings
  private_dns_zones = {
    enable_storage    = "privatelink.blob.core.windows.net"
    enable_sql        = "privatelink.database.windows.net"
    enable_keyvault   = "privatelink.vaultcore.azure.net"
    enable_acr        = "privatelink.azurecr.io"
    enable_aks        = "privatelink.${var.instance.spec.region}.azmk8s.io"
    enable_cosmos     = "privatelink.documents.azure.com"
    enable_servicebus = "privatelink.servicebus.windows.net"
    enable_eventhub   = "privatelink.servicebus.windows.net"
    enable_monitor    = "privatelink.monitor.azure.com"
    enable_cognitive  = "privatelink.cognitiveservices.azure.com"
  }

  private_endpoints_enabled = {
    for k, v in var.instance.spec.private_endpoints : k => lookup(local.private_dns_zones, k, "privatelink.${k}.azure.com") if v == true
  }
  # Calculate subnet mask from IP count
  subnet_mask_map = {
    "256"  = 24 # /24 = 256 IPs
    "512"  = 23 # /23 = 512 IPs  
    "1024" = 22 # /22 = 1024 IPs
    "2048" = 21 # /21 = 2048 IPs
    "4096" = 20 # /20 = 4096 IPs
    "8192" = 19 # /19 = 8192 IPs
  }

  # Use fixed CIDR allocation like the original (optional)
  use_fixed_cidrs = lookup(var.instance.spec, "use_fixed_cidr_allocation", false)

  # Fixed CIDR allocation (similar to original logic)
  fixed_private_subnets     = local.use_fixed_cidrs ? [for i in range(4) : cidrsubnet(var.instance.spec.vnet_cidr, 4, i)] : []
  fixed_public_subnets      = local.use_fixed_cidrs ? [cidrsubnet(var.instance.spec.vnet_cidr, 4, 12), cidrsubnet(var.instance.spec.vnet_cidr, 4, 14), cidrsubnet(var.instance.spec.vnet_cidr, 4, 15)] : []
  fixed_database_subnets    = local.use_fixed_cidrs ? [cidrsubnet(var.instance.spec.vnet_cidr, 4, 4), cidrsubnet(var.instance.spec.vnet_cidr, 4, 5)] : []
  fixed_gateway_subnet      = local.use_fixed_cidrs ? [cidrsubnet(var.instance.spec.vnet_cidr, 4, 6)] : []
  fixed_cache_subnet        = local.use_fixed_cidrs ? [cidrsubnet(var.instance.spec.vnet_cidr, 8, 112)] : []
  fixed_functions_subnets   = local.use_fixed_cidrs ? [cidrsubnet(var.instance.spec.vnet_cidr, 8, 113)] : []
  fixed_private_link_subnet = local.use_fixed_cidrs ? [cidrsubnet(var.instance.spec.vnet_cidr, 8, 114)] : []

  vnet_prefix_length = tonumber(split("/", var.instance.spec.vnet_cidr)[1])

  public_subnet_newbits   = local.subnet_mask_map[var.instance.spec.public_subnets.subnet_size] - local.vnet_prefix_length
  private_subnet_newbits  = local.subnet_mask_map[var.instance.spec.private_subnets.subnet_size] - local.vnet_prefix_length
  database_subnet_newbits = local.subnet_mask_map[var.instance.spec.database_subnets.subnet_size] - local.vnet_prefix_length

  # Calculate total number of subnets needed (only for dynamic allocation)
  public_total_subnets   = !local.use_fixed_cidrs ? length(var.instance.spec.availability_zones) * var.instance.spec.public_subnets.count_per_az : 0
  private_total_subnets  = !local.use_fixed_cidrs ? length(var.instance.spec.availability_zones) * var.instance.spec.private_subnets.count_per_az : 0
  database_total_subnets = !local.use_fixed_cidrs ? length(var.instance.spec.availability_zones) * var.instance.spec.database_subnets.count_per_az : 0

  # Specialized subnets (always use fixed allocation for these)
  gateway_subnets_enabled   = lookup(var.instance.spec, "enable_gateway_subnet", false)
  cache_subnets_enabled     = lookup(var.instance.spec, "enable_cache_subnet", false)
  functions_subnets_enabled = lookup(var.instance.spec, "enable_functions_subnet", false)
  private_link_svc_enabled  = lookup(var.instance.spec, "enable_private_link_service_subnet", false)

  # Create list of newbits for cidrsubnets function (dynamic allocation only)
  subnet_newbits = !local.use_fixed_cidrs ? concat(
    var.instance.spec.public_subnets.count_per_az > 0 ? [
      for i in range(local.public_total_subnets) : local.public_subnet_newbits
    ] : [],
    [for i in range(local.private_total_subnets) : local.private_subnet_newbits],
    [for i in range(local.database_total_subnets) : local.database_subnet_newbits]
  ) : []

  # Generate all subnet CIDRs using cidrsubnets function - this prevents overlaps (dynamic allocation)
  all_subnet_cidrs = !local.use_fixed_cidrs && length(local.subnet_newbits) > 0 ? cidrsubnets(var.instance.spec.vnet_cidr, local.subnet_newbits...) : []

  # Extract subnet CIDRs by type (dynamic allocation)
  public_subnet_cidrs = !local.use_fixed_cidrs && var.instance.spec.public_subnets.count_per_az > 0 ? slice(
    local.all_subnet_cidrs,
    0,
    local.public_total_subnets
  ) : local.fixed_public_subnets

  private_subnet_cidrs = !local.use_fixed_cidrs ? slice(
    local.all_subnet_cidrs,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets : 0,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets + local.private_total_subnets : local.private_total_subnets
  ) : local.fixed_private_subnets

  database_subnet_cidrs = !local.use_fixed_cidrs ? slice(
    local.all_subnet_cidrs,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets + local.private_total_subnets : local.private_total_subnets,
    var.instance.spec.public_subnets.count_per_az > 0 ? local.public_total_subnets + local.private_total_subnets + local.database_total_subnets : local.private_total_subnets + local.database_total_subnets
  ) : local.fixed_database_subnets

  # Create subnet mappings with AZ and CIDR
  public_subnets = var.instance.spec.public_subnets.count_per_az > 0 ? (
    local.use_fixed_cidrs ? [
      for i, cidr in local.public_subnet_cidrs : {
        az_index     = i % length(var.instance.spec.availability_zones)
        subnet_index = floor(i / length(var.instance.spec.availability_zones))
        az           = var.instance.spec.availability_zones[i % length(var.instance.spec.availability_zones)]
        cidr_block   = cidr
      }
      ] : flatten([
        for az_index, az in var.instance.spec.availability_zones : [
          for subnet_index in range(var.instance.spec.public_subnets.count_per_az) : {
            az_index     = az_index
            subnet_index = subnet_index
            az           = az
            cidr_block   = local.public_subnet_cidrs[az_index * var.instance.spec.public_subnets.count_per_az + subnet_index]
          }
        ]
    ])
  ) : []

  private_subnets = local.use_fixed_cidrs ? [
    for i, cidr in local.private_subnet_cidrs : {
      az_index     = i % length(var.instance.spec.availability_zones)
      subnet_index = floor(i / length(var.instance.spec.availability_zones))
      az           = var.instance.spec.availability_zones[i % length(var.instance.spec.availability_zones)]
      cidr_block   = cidr
    }
    ] : flatten([
      for az_index, az in var.instance.spec.availability_zones : [
        for subnet_index in range(var.instance.spec.private_subnets.count_per_az) : {
          az_index     = az_index
          subnet_index = subnet_index
          az           = az
          cidr_block   = local.private_subnet_cidrs[az_index * var.instance.spec.private_subnets.count_per_az + subnet_index]
        }
      ]
  ])

  database_subnets = local.use_fixed_cidrs ? [
    for i, cidr in local.database_subnet_cidrs : {
      az_index     = i % length(var.instance.spec.availability_zones)
      subnet_index = floor(i / length(var.instance.spec.availability_zones))
      az           = var.instance.spec.availability_zones[i % length(var.instance.spec.availability_zones)]
      cidr_block   = cidr
    }
    ] : flatten([
      for az_index, az in var.instance.spec.availability_zones : [
        for subnet_index in range(var.instance.spec.database_subnets.count_per_az) : {
          az_index     = az_index
          subnet_index = subnet_index
          az           = az
          cidr_block   = local.database_subnet_cidrs[az_index * var.instance.spec.database_subnets.count_per_az + subnet_index]
        }
      ]
  ])

  # Specialized subnets (always use fixed allocation)
  gateway_subnets = local.gateway_subnets_enabled ? [
    for i, cidr in local.fixed_gateway_subnet : {
      subnet_index = i
      cidr_block   = cidr
    }
  ] : []

  cache_subnets = local.cache_subnets_enabled ? [
    for i, cidr in local.fixed_cache_subnet : {
      subnet_index = i
      cidr_block   = cidr
    }
  ] : []

  functions_subnets = local.functions_subnets_enabled ? [
    for i, cidr in local.fixed_functions_subnets : {
      subnet_index = i
      cidr_block   = cidr
    }
  ] : []

  private_link_service_subnets = local.private_link_svc_enabled ? [
    for i, cidr in local.fixed_private_link_subnet : {
      subnet_index = i
      cidr_block   = cidr
    }
  ] : []

  # Private endpoints configuration with defaults
  private_endpoints = var.instance.spec.private_endpoints != null ? var.instance.spec.private_endpoints : {
    enable_storage    = true
    enable_sql        = true
    enable_keyvault   = true
    enable_acr        = true
    enable_aks        = false
    enable_cosmos     = false
    enable_servicebus = false
    enable_eventhub   = false
    enable_monitor    = false
    enable_cognitive  = false
  }

  # Resource naming prefix
  name_prefix = "${var.environment.unique_name}-${var.instance_name}"

  # Common tags
  common_tags = merge(
    var.environment.cloud_tags,
    lookup(var.instance.spec, "tags", {}),
    {
      Name        = local.name_prefix
      Environment = var.environment.name
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.instance.spec.region

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = [var.instance.spec.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

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

  # Enable private link endpoint policies
  enforce_private_link_endpoint_network_policies = true

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

  # Enable private link endpoint policies
  enforce_private_link_endpoint_network_policies = true

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

  # Enable private link service policies (this is why we need a dedicated subnet)
  enforce_private_link_service_network_policies = true

  lifecycle {
    ignore_changes = [service_endpoints, name]
  }
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in var.instance.spec.availability_zones : az => az
    } : var.instance.spec.public_subnets.count_per_az > 0 ? {
    single = var.instance.spec.availability_zones[0]
  } : {}

  name                = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-natgw-pip-${each.key}" : "${local.name_prefix}-natgw-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [each.value]

  tags = local.common_tags

  lifecycle {
    ignore_changes = [name]
  }
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in var.instance.spec.availability_zones : az => az
    } : var.instance.spec.public_subnets.count_per_az > 0 ? {
    single = var.instance.spec.availability_zones[0]
  } : {}

  name                    = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-natgw-${each.key}" : "${local.name_prefix}-natgw"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = [each.value]

  tags = local.common_tags

  lifecycle {
    ignore_changes = [name]
  }
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  for_each = azurerm_nat_gateway.main

  nat_gateway_id       = each.value.id
  public_ip_address_id = azurerm_public_ip.nat_gateway[each.key].id
}

# Route Table for Public Subnets
resource "azurerm_route_table" "public" {
  count = var.instance.spec.public_subnets.count_per_az > 0 ? 1 : 0

  name                = "${local.name_prefix}-public-rt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Associate Route Table with Public Subnets
resource "azurerm_subnet_route_table_association" "public" {
  for_each = azurerm_subnet.public

  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.public[0].id
}

# Route Table for Private Subnets
resource "azurerm_route_table" "private" {
  for_each = var.instance.spec.nat_gateway.strategy == "per_az" ? {
    for az in var.instance.spec.availability_zones : az => az
    } : var.instance.spec.public_subnets.count_per_az > 0 ? {
    single = "1"
  } : {}

  name                = var.instance.spec.nat_gateway.strategy == "per_az" ? "${local.name_prefix}-private-rt-${each.key}" : "${local.name_prefix}-private-rt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Associate Route Table with Private Subnets
resource "azurerm_subnet_route_table_association" "private" {
  for_each = azurerm_subnet.private

  subnet_id      = each.value.id
  route_table_id = var.instance.spec.nat_gateway.strategy == "per_az" ? azurerm_route_table.private[split("-", each.key)[0]].id : azurerm_route_table.private["single"].id
}

# Route Table for Database Subnets (isolated)
resource "azurerm_route_table" "database" {
  for_each = {
    for az in var.instance.spec.availability_zones : az => az
  }

  name                = "${local.name_prefix}-database-rt-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Associate Route Table with Database Subnets
resource "azurerm_subnet_route_table_association" "database" {
  for_each = azurerm_subnet.database

  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.database[split("-", each.key)[0]].id
}

# Associate NAT Gateway with Private Route Tables
resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each = {
    for k, v in azurerm_subnet.private : k => v
    if var.instance.spec.public_subnets.count_per_az > 0
  }

  subnet_id      = each.value.id
  nat_gateway_id = var.instance.spec.nat_gateway.strategy == "per_az" ? azurerm_nat_gateway.main[split("-", each.key)[0]].id : azurerm_nat_gateway.main["single"].id
}

# Associate NAT Gateway with Functions Subnets
resource "azurerm_subnet_nat_gateway_association" "functions" {
  for_each = {
    for k, v in azurerm_subnet.functions : k => v
    if var.instance.spec.public_subnets.count_per_az > 0
  }

  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.main["1"].id # Functions typically use single NAT Gateway
}

# Network Security Group - Allow all within VNet (similar to original logic)
resource "azurerm_network_security_group" "allow_all_default" {
  name                = "${local.name_prefix}-allow-all-default-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.instance.spec.vnet_cidr
    destination_address_prefix = "*"
    description                = "Allowing connection from within vnet"
  }

  tags = merge(local.common_tags, {
    Terraform = "true"
  })

  lifecycle {
    ignore_changes = [name]
  }
}

# Security Group for VPC Endpoints (keep existing for private endpoints)
resource "azurerm_network_security_group" "vpc_endpoints" {
  count = anytrue([
    try(local.private_endpoints.enable_storage, false),
    try(local.private_endpoints.enable_sql, false),
    try(local.private_endpoints.enable_keyvault, false),
    try(local.private_endpoints.enable_acr, false),
    try(local.private_endpoints.enable_aks, false),
    try(local.private_endpoints.enable_cosmos, false),
    try(local.private_endpoints.enable_servicebus, false),
    try(local.private_endpoints.enable_eventhub, false),
    try(local.private_endpoints.enable_monitor, false),
    try(local.private_endpoints.enable_cognitive, false)
  ]) ? 1 : 0

  name                = "${local.name_prefix}-private-endpoints-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.instance.spec.vnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Network Security Groups for Subnets - Apply the allow-all NSG to all subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = azurerm_subnet.public

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each = azurerm_subnet.private

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  for_each = azurerm_subnet.database

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  for_each = azurerm_subnet.gateway

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "cache" {
  for_each = azurerm_subnet.cache

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "functions" {
  for_each = azurerm_subnet.functions

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "private_link_service" {
  for_each = azurerm_subnet.private_link_service

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

# Private DNS Zone for Private Endpoints
resource "azurerm_private_dns_zone" "private_endpoints" {
  for_each = {
    for k, v in var.instance.spec.private_endpoints : k => lookup(local.private_dns_zones, k, "privatelink.${k}.azure.com") if v == true
  }

  name                = each.value
  resource_group_name = azurerm_resource_group.main.name

  tags = var.instance.spec.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "private_endpoints" {
  for_each = azurerm_private_dns_zone.private_endpoints

  name                  = "${local.name_prefix}-${each.key}-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = local.common_tags
}

# Example Storage Account (for demonstration of private endpoint)
resource "azurerm_storage_account" "example" {
  count = try(local.private_endpoints.enable_storage, false) ? 1 : 0

  name                     = substr(replace(replace(lower(local.name_prefix), "-", ""), "_", ""), 0, 20)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Disable public access


  tags = local.common_tags
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  count = try(local.private_endpoints.enable_storage, false) ? 1 : 0

  name                = "${local.name_prefix}-storage-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = values(azurerm_subnet.private)[0].id

  private_service_connection {
    name                           = "${local.name_prefix}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.example[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_endpoints["enable_storage"].id]
  }

  tags = local.common_tags
}