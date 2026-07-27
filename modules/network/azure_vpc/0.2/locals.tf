#########################################################################
# Local Values and Calculations                                         #
#########################################################################

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
