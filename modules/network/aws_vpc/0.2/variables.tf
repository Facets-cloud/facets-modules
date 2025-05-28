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
  type = object({
    spec = object({
      vpc_cidr           = string
      region             = string
      availability_zones = list(string)

      public_subnets = object({
        count_per_az = number
        subnet_size  = string
      })

      eks_subnets = object({
        subnet_size  = string
        cluster_name = string
      })

      nat_gateway = object({
        strategy = string
      })

      vpc_endpoints = optional(object({
        enable_s3           = optional(bool, true)
        enable_dynamodb     = optional(bool, true)
        enable_ecr_api      = optional(bool, true)
        enable_ecr_dkr      = optional(bool, true)
        enable_eks          = optional(bool, false)
        enable_ec2          = optional(bool, false)
        enable_ssm          = optional(bool, true)
        enable_ssm_messages = optional(bool, true)
        enable_ec2_messages = optional(bool, true)
        enable_kms          = optional(bool, false)
        enable_logs         = optional(bool, false)
        enable_monitoring   = optional(bool, false)
        enable_sts          = optional(bool, false)
        enable_lambda       = optional(bool, false)
      }), {})
    })
  })

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
    ], var.instance.spec.region)
    error_message = "Region must be a valid AWS region from the supported list."
  }

  validation {
    condition     = length(var.instance.spec.availability_zones) >= 2 && length(var.instance.spec.availability_zones) <= 4
    error_message = "You must specify between 2 and 4 availability zones."
  }

  validation {
    condition = alltrue([
      for az in var.instance.spec.availability_zones :
      can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))
    ])
    error_message = "Availability zones must be in format like 'us-east-1a'."
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
    condition     = contains(["256", "512", "1024", "2048", "4096", "8192"], var.instance.spec.eks_subnets.subnet_size)
    error_message = "EKS subnet size must be one of: 256, 512, 1024, 2048, 4096, 8192."
  }

  validation {
    condition     = contains(["single", "per_az"], var.instance.spec.nat_gateway.strategy)
    error_message = "NAT Gateway strategy must be either 'single' or 'per_az'."
  }
}
