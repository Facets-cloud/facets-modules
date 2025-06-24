variable "instance" {
  description = "A Kubernetes EKS cluster module with auto mode enabled by default and all necessary configurations preset."
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      kubernetes_version = string
      node_groups = object({
        default = object({
          enabled         = bool
          max_size_cpu    = number
          max_size_memory = number
          instance_types  = string
          capacity_type   = string
        })
        dedicated = object({
          enabled         = bool
          max_size_cpu    = number
          max_size_memory = number
          instance_types  = string
          capacity_type   = string
        })
      })
      cluster_endpoint_public_access         = bool
      cluster_endpoint_private_access        = bool
      cluster_endpoint_public_access_cidrs   = list(string)
      cluster_endpoint_private_access_cidrs  = list(string)
      cloudwatch_log_group_retention_in_days = number
      cluster_enabled_log_types              = list(string)
      enable_cluster_encryption              = bool
      default_reclaim_policy                 = string
      kms = object({
        deletion_window_in_days = number
        enable_rotation         = bool
        rotation_period_in_days = number
      })
      tags = map(string)
      secret_copier = object({
        enabled = bool
        values  = map(any)
      })
    })
  })
  validation {
    condition = (
      (!var.instance.spec.node_groups.default.enabled || contains(["on-demand", "spot"], var.instance.spec.node_groups.default.capacity_type)) &&
      (!var.instance.spec.node_groups.dedicated.enabled || contains(["on-demand", "spot"], var.instance.spec.node_groups.dedicated.capacity_type))
    )
    error_message = "Invalid capacity_type for enabled node group(s). Allowed values are 'on-demand' or 'spot'."
  }
}

variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
  validation {
    condition     = var.instance_name != null
    error_message = "instance_name is required"
  }
  validation {
    condition     = regex("^[a-zA-Z0-9-]+$", var.instance_name) && length(var.instance_name) <= 20
    error_message = "Instance name must contain only alphanumeric characters and hyphens (-), and be no more than 20 characters long."
  }
}

variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = map(string)
  })
}

variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
    network_details = object({
      attributes = object({
        vpc_id                          = string
        vpc_cidr_block                  = string
        nat_gateway_ids                 = list(string)
        public_subnet_ids               = list(string)
        availability_zones              = list(string)
        private_subnet_ids              = list(string)
        internet_gateway_id             = string
        vpc_endpoint_s3_id              = optional(string)
        vpc_endpoint_dynamodb_id        = optional(string)
        vpc_endpoint_ecr_api_id         = optional(string)
        vpc_endpoint_ecr_dkr_id         = optional(string)
        vpc_endpoints_security_group_id = optional(string)
      })
    })
  })
}
