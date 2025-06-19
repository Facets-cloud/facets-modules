variable "instance" {
  type = object({
    spec = object({
      choose_vpc_type                 = string
      azs                             = list(string)
      vpc_cidr                        = string
      enable_multi_az                 = bool
      existing_vpc_id                 = string
      nat_gateway_strategy            = optional(string, "create_new_nat_gateways")
      existing_nat_gateway_ids        = optional(string, "")
      existing_public_route_table_ids = optional(string, "")
    })
  })
  description = "Instance configuration containing spec and other metadata"

  validation {
    condition     = contains(["create_new_vpc", "use_existing_vpc"], var.instance.spec.choose_vpc_type)
    error_message = "VPC type must be either 'create_new_vpc' or 'use_existing_vpc'."
  }

  validation {
    condition     = can(regex("^(10\\.(\\d{1,3}\\.){2}\\d{1,3}/(2[0-8]|[89]|1[0-9])|172\\.(1[6-9]|2[0-9]|3[01])\\.(\\d{1,3}\\.){1}\\d{1,3}/(2[0-8]|[12][0-9])|192\\.168\\.(\\d{1,3}\\.){1}\\d{1,3}/(2[0-8]|[12][0-9]|1[6-9]))$", var.instance.spec.vpc_cidr))
    error_message = "The provided CIDR block is invalid. Please ensure it is a valid private IP range in CIDR notation."
  }

  validation {
    condition     = length(var.instance.spec.azs) >= 1 && length(var.instance.spec.azs) <= 3
    error_message = "At least 1 and at most 3 availability zones must be specified."
  }

  validation {
    condition     = var.instance.spec.choose_vpc_type == "use_existing_vpc" ? var.instance.spec.existing_vpc_id != "" : true
    error_message = "Existing VPC ID must be provided when using existing VPC."
  }

  validation {
    condition     = contains(["create_new_nat_gateways", "use_existing_nat_gateways"], var.instance.spec.nat_gateway_strategy)
    error_message = "NAT Gateway strategy must be either 'create_new_nat_gateways' or 'use_existing_nat_gateways'."
  }

  validation {
    condition = (
      var.instance.spec.choose_vpc_type == "use_existing_vpc" &&
      var.instance.spec.nat_gateway_strategy == "use_existing_nat_gateways"
    ) ? var.instance.spec.existing_nat_gateway_ids != "" : true
    error_message = "Existing NAT Gateway IDs must be provided when using existing NAT Gateways."
  }

  validation {
    condition = (
      var.instance.spec.choose_vpc_type == "use_existing_vpc" &&
      var.instance.spec.nat_gateway_strategy == "use_existing_nat_gateways"
    ) ? var.instance.spec.existing_public_route_table_ids != "" : true
    error_message = "Existing public route table IDs must be provided when using existing NAT Gateways."
  }
}

variable "instance_name" {
  type        = string
  description = "Unique architectural name for the resource"
}

variable "environment" {
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = map(string)
  })
  description = "Environment metadata including name, unique identifier and cloud tags"
}

variable "inputs" {
  type        = any
  default     = {}
  description = "Inputs from other modules"
}