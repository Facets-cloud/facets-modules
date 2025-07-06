variable "instance_name" {
  description = "Name of the instance"
  type        = string
}

variable "environment" {
  description = "Environment configuration"
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = map(string)
  })
}

variable "inputs" {
  description = "Input references from other modules"
  type        = map(any)
  default     = {}
}

variable "instance" {
  description = "Instance configuration"
  type        = any

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.instance.spec.vpc_cidr))
    error_message = "VPC CIDR must be a valid IP block (e.g., 10.0.0.0/16)."
  }

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-north-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2", "ap-south-1",
      "ca-central-1", "sa-east-1"
    ], var.inputs.cloud_account.attributes.aws_region)
    error_message = "Region must be a valid AWS region from the supported list."
  }

  validation {
    condition = lookup(var.instance.spec, "auto_select_azs", false) || (
      lookup(var.instance.spec, "availability_zones", null) != null &&
      length(var.instance.spec.availability_zones) >= 2 &&
      length(var.instance.spec.availability_zones) <= 4
    )
    error_message = "When auto_select_azs is false, you must specify between 2 and 4 availability zones."
  }

  validation {
    condition = lookup(var.instance.spec, "auto_select_azs", false) || (
      lookup(var.instance.spec, "availability_zones", null) != null &&
      alltrue([
        for az in var.instance.spec.availability_zones :
        can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))
      ])
    )
    error_message = "When specified, availability zones must be in format like 'us-east-1a'."
  }

  validation {
    condition     = var.instance.spec.public_subnets.count_per_az >= 0 && var.instance.spec.public_subnets.count_per_az <= 3
    error_message = "Public subnets count per AZ must be between 0 and 3."
  }

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.instance.spec.public_subnets.subnet_size)
    error_message = "Public subnet size must be one of: 256, 512, 1024, 2048, 4096."
  }

  validation {
    condition     = var.instance.spec.private_subnets.count_per_az >= 1 && var.instance.spec.private_subnets.count_per_az <= 3
    error_message = "Private subnets count per AZ must be between 1 and 3."
  }

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096", "8192"], var.instance.spec.private_subnets.subnet_size)
    error_message = "Private subnet size must be one of: 256, 512, 1024, 2048, 4096, 8192."
  }

  validation {
    condition     = var.instance.spec.database_subnets.count_per_az >= 1 && var.instance.spec.database_subnets.count_per_az <= 3
    error_message = "Database subnets count per AZ must be between 1 and 3."
  }

  validation {
    condition     = contains(["256", "512", "1024", "2048"], var.instance.spec.database_subnets.subnet_size)
    error_message = "Database subnet size must be one of: 256, 512, 1024, 2048."
  }

  validation {
    condition     = contains(["single", "per_az"], var.instance.spec.nat_gateway.strategy)
    error_message = "NAT Gateway strategy must be either 'single' or 'per_az'."
  }

  # Enhanced validation: VPC CIDR capacity check
  validation {
    condition = (
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.public_subnets.count_per_az * tonumber(var.instance.spec.public_subnets.subnet_size) +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.private_subnets.count_per_az * tonumber(var.instance.spec.private_subnets.subnet_size) +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.database_subnets.count_per_az * tonumber(var.instance.spec.database_subnets.subnet_size)
    ) <= pow(2, 32 - tonumber(split("/", var.instance.spec.vpc_cidr)[1]))
    error_message = "Total IP allocation exceeds VPC capacity. For your VPC CIDR ${var.instance.spec.vpc_cidr}, you have ${pow(2, 32 - tonumber(split("/", var.instance.spec.vpc_cidr)[1]))} total IPs available."
  }

  # Enhanced validation: Subnet size compatibility with VPC CIDR
  validation {
    condition = alltrue([
      # Public subnets compatibility
      var.instance.spec.public_subnets.count_per_az == 0 || (
        lookup({
          "256"  = 24,
          "512"  = 23,
          "1024" = 22,
          "2048" = 21,
          "4096" = 20
        }, var.instance.spec.public_subnets.subnet_size, 32) >= tonumber(split("/", var.instance.spec.vpc_cidr)[1])
      ),
      # Private subnets compatibility  
      lookup({
        "256"  = 24,
        "512"  = 23,
        "1024" = 22,
        "2048" = 21,
        "4096" = 20,
        "8192" = 19
      }, var.instance.spec.private_subnets.subnet_size, 32) >= tonumber(split("/", var.instance.spec.vpc_cidr)[1]),
      # Database subnets compatibility
      lookup({
        "256"  = 24,
        "512"  = 23,
        "1024" = 22,
        "2048" = 21
      }, var.instance.spec.database_subnets.subnet_size, 32) >= tonumber(split("/", var.instance.spec.vpc_cidr)[1])
    ])
    error_message = "One or more subnet sizes are incompatible with VPC CIDR ${var.instance.spec.vpc_cidr}. Subnet sizes must require a subnet mask greater than or equal to the VPC prefix length."
  }

  # Enhanced validation: Individual subnet type feasibility  
  validation {
    condition = var.instance.spec.public_subnets.count_per_az == 0 || (
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.public_subnets.count_per_az <=
      pow(2, lookup({
        "256"  = 24,
        "512"  = 23,
        "1024" = 22,
        "2048" = 21,
        "4096" = 20
      }, var.instance.spec.public_subnets.subnet_size, 32) - tonumber(split("/", var.instance.spec.vpc_cidr)[1]))
    )
    error_message = "Too many public subnets requested for VPC CIDR ${var.instance.spec.vpc_cidr} and subnet size ${var.instance.spec.public_subnets.subnet_size}."
  }

  validation {
    condition = (
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.private_subnets.count_per_az <=
      pow(2, lookup({
        "256"  = 24,
        "512"  = 23,
        "1024" = 22,
        "2048" = 21,
        "4096" = 20,
        "8192" = 19
      }, var.instance.spec.private_subnets.subnet_size, 32) - tonumber(split("/", var.instance.spec.vpc_cidr)[1]))
    )
    error_message = "Too many private subnets requested for VPC CIDR ${var.instance.spec.vpc_cidr} and subnet size ${var.instance.spec.private_subnets.subnet_size}."
  }

  validation {
    condition = (
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.database_subnets.count_per_az <=
      pow(2, lookup({
        "256"  = 24,
        "512"  = 23,
        "1024" = 22,
        "2048" = 21
      }, var.instance.spec.database_subnets.subnet_size, 32) - tonumber(split("/", var.instance.spec.vpc_cidr)[1]))
    )
    error_message = "Too many database subnets requested for VPC CIDR ${var.instance.spec.vpc_cidr} and subnet size ${var.instance.spec.database_subnets.subnet_size}."
  }

  # Enhanced validation: Reasonable total subnet limits for practical usage
  validation {
    condition = (
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.public_subnets.count_per_az +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.private_subnets.count_per_az +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", []))) * var.instance.spec.database_subnets.count_per_az
    ) <= 50
    error_message = "Total number of subnets across all types exceeds practical limit of 50. Consider reducing subnet counts or using larger subnet sizes."
  }

  # Enhanced validation: Ensure at least one private subnet for best practices
  validation {
    condition     = var.instance.spec.private_subnets.count_per_az >= 1
    error_message = "At least one private subnet per AZ is required for security best practices."
  }

  # Enhanced validation: VPC CIDR size limits for practical usage
  validation {
    condition = (
      tonumber(split("/", var.instance.spec.vpc_cidr)[1]) >= 16 &&
      tonumber(split("/", var.instance.spec.vpc_cidr)[1]) <= 28
    )
    error_message = "VPC CIDR prefix must be between /16 and /28 for practical usage. Your CIDR ${var.instance.spec.vpc_cidr} has prefix /${tonumber(split("/", var.instance.spec.vpc_cidr)[1])}."
  }

  # Enhanced validation: CIDR allocation feasibility check  
  # Test if cidrsubnets function can successfully allocate all requested subnets
  validation {
    condition = (
      # First check that all newbits values are positive (subnet prefix >= VPC prefix)
      alltrue([
        # Public subnets newbits check
        var.instance.spec.public_subnets.count_per_az == 0 || (
          lookup({ "256" = 24, "512" = 23, "1024" = 22, "2048" = 21, "4096" = 20 }, var.instance.spec.public_subnets.subnet_size, 24) >= tonumber(split("/", var.instance.spec.vpc_cidr)[1])
        ),
        # Private subnets newbits check
        lookup({ "256" = 24, "512" = 23, "1024" = 22, "2048" = 21, "4096" = 20, "8192" = 19 }, var.instance.spec.private_subnets.subnet_size, 24) >= tonumber(split("/", var.instance.spec.vpc_cidr)[1]),
        # Database subnets newbits check  
        lookup({ "256" = 24, "512" = 23, "1024" = 22, "2048" = 21 }, var.instance.spec.database_subnets.subnet_size, 24) >= tonumber(split("/", var.instance.spec.vpc_cidr)[1])
      ]) &&
      # Then test if cidrsubnets can actually allocate all subnets
      can(
        cidrsubnets(
          var.instance.spec.vpc_cidr,
          # Create list of newbits for all subnets (same logic as main.tf)
          concat(
            var.instance.spec.public_subnets.count_per_az > 0 ? [
              for i in range(length(var.instance.spec.availability_zones) * var.instance.spec.public_subnets.count_per_az) :
              lookup({ "256" = 24, "512" = 23, "1024" = 22, "2048" = 21, "4096" = 20 }, var.instance.spec.public_subnets.subnet_size, 24) - tonumber(split("/", var.instance.spec.vpc_cidr)[1])
            ] : [],
            [
              for i in range(length(var.instance.spec.availability_zones) * var.instance.spec.private_subnets.count_per_az) :
              lookup({ "256" = 24, "512" = 23, "1024" = 22, "2048" = 21, "4096" = 20, "8192" = 19 }, var.instance.spec.private_subnets.subnet_size, 24) - tonumber(split("/", var.instance.spec.vpc_cidr)[1])
            ],
            [
              for i in range(length(var.instance.spec.availability_zones) * var.instance.spec.database_subnets.count_per_az) :
              lookup({ "256" = 24, "512" = 23, "1024" = 22, "2048" = 21 }, var.instance.spec.database_subnets.subnet_size, 24) - tonumber(split("/", var.instance.spec.vpc_cidr)[1])
            ]
          )...
        )
      )
    )
    error_message = "CIDR allocation conflict! Cannot allocate requested subnets in VPC ${var.instance.spec.vpc_cidr}. Check: (1) All subnet sizes must fit within VPC (subnet prefix ≥ VPC prefix), (2) Total subnet space must fit without overlap. Requested: ${length(var.instance.spec.availability_zones) * var.instance.spec.public_subnets.count_per_az} public (${var.instance.spec.public_subnets.subnet_size} IPs), ${length(var.instance.spec.availability_zones) * var.instance.spec.private_subnets.count_per_az} private (${var.instance.spec.private_subnets.subnet_size} IPs), ${length(var.instance.spec.availability_zones) * var.instance.spec.database_subnets.count_per_az} database (${var.instance.spec.database_subnets.subnet_size} IPs)."
  }

  # Enhanced validation: NAT Gateway requirements
  validation {
    condition     = var.instance.spec.public_subnets.count_per_az == 0 || var.instance.spec.nat_gateway.strategy != null
    error_message = "NAT Gateway strategy must be specified when private subnets are configured, but no public subnets are available for NAT placement."
  }

  # Validation for tags: ensure all tag values are strings
  validation {
    condition = alltrue([
      for k, v in var.instance.spec.tags : can(tostring(v))
    ])
    error_message = "All tag values must be strings."
  }

  # Validation for tags: ensure tag keys don't conflict with reserved keys
  validation {
    condition = alltrue([
      for k in keys(var.instance.spec.tags) : !contains(["Name", "Environment"], k)
    ])
    error_message = "Tag keys 'Name' and 'Environment' are reserved and will be overridden by the module."
  }
}
