variable "instance" {
  description = "A Kubernetes EKS cluster module with auto mode enabled by default and all necessary configurations preset."
  type        = any
  validation {
    condition = (
      (!var.instance.spec.node_pools.default.enabled || contains(["on-demand", "spot"], var.instance.spec.node_pools.default.capacity_type)) &&
      (!var.instance.spec.node_pools.dedicated.enabled || contains(["on-demand", "spot"], var.instance.spec.node_pools.dedicated.capacity_type))
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
  type        = any
}

variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type        = any
}
