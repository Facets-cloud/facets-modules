variable "instance" {
  description = "A Kubernetes EKS cluster module with auto mode enabled by default and all necessary configurations preset."
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      kubernetes_version = string
      auto_mode          = bool
      node_groups = object({
        default = object({
          enabled        = bool
          desired_size   = number
          min_size       = number
          max_size       = number
          instance_types = string
          disk_size      = number
          capacity_type  = string
        })
        dedicated = object({
          enabled        = bool
          desired_size   = number
          min_size       = number
          max_size       = number
          instance_types = string
          disk_size      = number
          capacity_type  = string
        })
      })
      cluster_endpoint_public_access       = bool
      cluster_endpoint_private_access      = bool
      cluster_endpoint_public_access_cidrs = string
      enable_cluster_encryption            = bool
    })
  })
  validation {
    condition = var.instance.spec.auto_mode == true || var.instance.spec.auto_mode == false
    error_message = "Invalid auto_mode. Allowed values are 'true' or 'false'. and it can't be null"
  }
  validation {
    condition = (
      (!var.instance.spec.node_groups.default.enabled || contains(["ON_DEMAND", "SPOT"], var.instance.spec.node_groups.default.capacity_type)) &&
      (!var.instance.spec.node_groups.dedicated.enabled || contains(["ON_DEMAND", "SPOT"], var.instance.spec.node_groups.dedicated.capacity_type))
    )
    error_message = "Invalid capacity_type for enabled node group(s). Allowed values are 'ON_DEMAND' or 'SPOT'."
  }

}

variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
  validation {
    condition = var.instance_name != null
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
        legacy_outputs = object({
          vpc_details = object({
            vpc_id             = string
            private_subnet_ids = list(string)
          })
        })
      })
    })
  })
}
