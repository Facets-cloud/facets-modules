#########################################################################
# Facets Module Variables                                               #
#                                                                       #
# Auto-injected variables that every Facets module receives             #
#########################################################################

variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.instance_name))
    error_message = "Instance name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = map(string)
  })

  validation {
    condition     = can(var.environment.name) && can(var.environment.unique_name) && can(var.environment.cloud_tags)
    error_message = "Environment must contain name, unique_name, and cloud_tags."
  }
}

variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type        = any
  default     = {}
}

#########################################################################
# Instance Configuration Schema                                         #
#                                                                       #
# Comprehensive validation for all module specifications                #
#########################################################################

variable "instance" {
  description = "The resource instance configuration"
  type = object({
    spec = object({
      # Core VNet Configuration
      vnet_cidr          = string
      region             = string
      availability_zones = list(string)

      # Optional CIDR Strategy
      use_fixed_cidr_allocation = optional(bool, false)

      # Public Subnets Configuration
      public_subnets = object({
        count_per_az = number
        subnet_size  = string
      })

      # Private Subnets Configuration
      private_subnets = object({
        count_per_az = number
        subnet_size  = string
      })

      # Database Subnets Configuration
      database_subnets = object({
        count_per_az = number
        subnet_size  = string
      })

      # Specialized Subnet Toggles
      enable_gateway_subnet              = optional(bool, false)
      enable_cache_subnet                = optional(bool, false)
      enable_functions_subnet            = optional(bool, false)
      enable_private_link_service_subnet = optional(bool, false)
      enable_aks                         = optional(bool, false)

      # NAT Gateway Configuration
      nat_gateway = object({
        strategy = string
      })

      # Private Endpoints Configuration
      private_endpoints = optional(object({
        enable_storage    = optional(bool, true)
        enable_sql        = optional(bool, true)
        enable_keyvault   = optional(bool, true)
        enable_acr        = optional(bool, true)
        enable_aks        = optional(bool, false)
        enable_cosmos     = optional(bool, false)
        enable_servicebus = optional(bool, false)
        enable_eventhub   = optional(bool, false)
        enable_monitor    = optional(bool, false)
        enable_cognitive  = optional(bool, false)
      }))

      # Additional Tags
      tags = optional(map(string), {})
    })
  })

  #########################################################################
  # VNet CIDR Validation                                                  #
  #########################################################################
  validation {
    condition     = can(cidrhost(var.instance.spec.vnet_cidr, 0))
    error_message = "VNet CIDR must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.instance.spec.vnet_cidr))
    error_message = "VNet CIDR must follow the format x.x.x.x/xx (e.g., 10.0.0.0/16)."
  }

  #########################################################################
  # Region Validation                                                     #
  #########################################################################
  validation {
    condition     = length(var.instance.spec.region) > 0
    error_message = "Azure region cannot be empty."
  }

  validation {
    condition = contains([
      "eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast",
      "southeastasia", "northeurope", "swedencentral", "uksouth", "westeurope",
      "centralus", "southafricanorth", "centralindia", "eastasia", "japaneast",
      "koreacentral", "canadacentral", "francecentral", "germanywestcentral",
      "norwayeast", "switzerlandnorth", "uaenorth", "brazilsouth", "eastus2euap",
      "qatarcentral", "centralusstage", "eastusstage", "eastus2stage", "northcentralusstage",
      "southcentralusstage", "westusstage", "westus2stage", "asia", "asiapacific",
      "australia", "brazil", "canada", "europe", "france", "germany", "global",
      "india", "japan", "korea", "norway", "singapore", "southafrica", "switzerland",
      "uae", "uk", "unitedstates"
    ], var.instance.spec.region)
    error_message = "Region must be a valid Azure region name."
  }

  #########################################################################
  # Availability Zones Validation                                         #
  #########################################################################
  validation {
    condition     = length(var.instance.spec.availability_zones) >= 1 && length(var.instance.spec.availability_zones) <= 3
    error_message = "Availability zones must contain between 1 and 3 zones."
  }

  validation {
    condition = alltrue([
      for zone in var.instance.spec.availability_zones :
      contains(["1", "2", "3"], zone)
    ])
    error_message = "Availability zones must be \"1\", \"2\", or \"3\"."
  }

  #########################################################################
  # Public Subnets Validation                                            #
  #########################################################################
  validation {
    condition     = var.instance.spec.public_subnets.count_per_az >= 0 && var.instance.spec.public_subnets.count_per_az <= 3
    error_message = "Public subnets count per AZ must be between 0 and 3."
  }

  validation {
    condition = contains([
      "256", "512", "1024", "2048", "4096", "8192"
    ], var.instance.spec.public_subnets.subnet_size)
    error_message = "Public subnet size must be one of: 256, 512, 1024, 2048, 4096, 8192."
  }

  #########################################################################
  # Private Subnets Validation                                           #
  #########################################################################
  validation {
    condition     = var.instance.spec.private_subnets.count_per_az >= 1 && var.instance.spec.private_subnets.count_per_az <= 3
    error_message = "Private subnets count per AZ must be between 1 and 3."
  }

  validation {
    condition = contains([
      "256", "512", "1024", "2048", "4096", "8192"
    ], var.instance.spec.private_subnets.subnet_size)
    error_message = "Private subnet size must be one of: 256, 512, 1024, 2048, 4096, 8192."
  }

  #########################################################################
  # Database Subnets Validation                                          #
  #########################################################################
  validation {
    condition     = var.instance.spec.database_subnets.count_per_az >= 0 && var.instance.spec.database_subnets.count_per_az <= 3
    error_message = "Database subnets count per AZ must be between 0 and 3."
  }

  validation {
    condition = contains([
      "256", "512", "1024", "2048", "4096", "8192"
    ], var.instance.spec.database_subnets.subnet_size)
    error_message = "Database subnet size must be one of: 256, 512, 1024, 2048, 4096, 8192."
  }

  #########################################################################
  # NAT Gateway Strategy Validation                                       #
  #########################################################################
  validation {
    condition = contains([
      "single", "per_az"
    ], var.instance.spec.nat_gateway.strategy)
    error_message = "NAT Gateway strategy must be either 'single' or 'per_az'."
  }

  #########################################################################
  # Logical Validations                                                   #
  #########################################################################
  validation {
    condition     = var.instance.spec.public_subnets.count_per_az > 0 || var.instance.spec.nat_gateway.strategy == "single"
    error_message = "NAT Gateway requires at least one public subnet when using 'per_az' strategy."
  }

  validation {
    condition = (
      (var.instance.spec.public_subnets.count_per_az > 0 ?
      length(var.instance.spec.availability_zones) * var.instance.spec.public_subnets.count_per_az : 0) +
      length(var.instance.spec.availability_zones) * var.instance.spec.private_subnets.count_per_az +
      length(var.instance.spec.availability_zones) * var.instance.spec.database_subnets.count_per_az
    ) <= 20
    error_message = "Total number of subnets across all types and AZs cannot exceed 20."
  }

  validation {
    condition     = !var.instance.spec.enable_aks || var.instance.spec.private_subnets.count_per_az > 0
    error_message = "AKS integration requires at least one private subnet per AZ."
  }

  #########################################################################
  # CIDR Size Validation                                                  #
  #########################################################################
  validation {
    condition     = tonumber(split("/", var.instance.spec.vnet_cidr)[1]) <= 24
    error_message = "VNet CIDR prefix must be /24 or larger (smaller number) to accommodate all configured subnets."
  }
}
