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
    condition = lookup(var.instance.spec, "auto_select_azs", false) || (
      lookup(var.instance.spec, "availability_zones", null) != null &&
      length(lookup(var.instance.spec, "availability_zones", [])) >= 2 &&
      length(lookup(var.instance.spec, "availability_zones", [])) <= 4
    )
    error_message = "When auto_select_azs is false, you must specify between 2 and 4 availability zones."
  }

  validation {
    condition = lookup(var.instance.spec, "auto_select_azs", false) || (
      lookup(var.instance.spec, "availability_zones", null) != null &&
      alltrue([
        for az in lookup(var.instance.spec, "availability_zones", []) :
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

  # Enhanced validation: VPC CIDR capacity check - need to calculate AZ count dynamically
  validation {
    condition = (
      # Calculate AZ count based on auto_select_azs
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.public_subnets.count_per_az * tonumber(var.instance.spec.public_subnets.subnet_size) +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.private_subnets.count_per_az * tonumber(var.instance.spec.private_subnets.subnet_size) +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.database_subnets.count_per_az * tonumber(var.instance.spec.database_subnets.subnet_size)
    ) <= pow(2, 32 - tonumber(split("/", var.instance.spec.vpc_cidr)[1]))
    error_message = "Total IP allocation exceeds VPC capacity. For your VPC CIDR, you have ${pow(2, 32 - tonumber(split("/", var.instance.spec.vpc_cidr)[1]))} total IPs available."
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
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.public_subnets.count_per_az <=
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
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.private_subnets.count_per_az <=
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
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.database_subnets.count_per_az <=
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
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.public_subnets.count_per_az +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.private_subnets.count_per_az +
      (lookup(var.instance.spec, "auto_select_azs", false) ? 3 : length(lookup(var.instance.spec, "availability_zones", ["us-east-1a", "us-east-1b"]))) * var.instance.spec.database_subnets.count_per_az
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

  # Enhanced validation: NAT Gateway requirements
  validation {
    condition     = var.instance.spec.public_subnets.count_per_az == 0 || var.instance.spec.nat_gateway.strategy != null
    error_message = "NAT Gateway strategy must be specified when private subnets are configured, but no public subnets are available for NAT placement."
  }

  # Validation for tags: ensure all tag values are strings
  validation {
    condition = lookup(var.instance.spec, "tags", null) == null || alltrue([
      for k, v in var.instance.spec.tags : can(tostring(v))
    ])
    error_message = "All tag values must be strings."
  }

  # Validation for tags: ensure tag keys don't conflict with reserved keys
  validation {
    condition = lookup(var.instance.spec, "tags", null) == null || alltrue([
      for k in keys(var.instance.spec.tags) : !contains(["Name", "Environment"], k)
    ])
    error_message = "Tag keys 'Name' and 'Environment' are reserved and will be overridden by the module."
  }
}
