variable "instance" {
  type = any

  validation {
    condition     = contains(["Follow", "None"], var.instance.spec.cname_strategy)
    error_message = "cname_strategy must be either 'Follow' or 'None'."
  }

  validation {
    condition     = var.instance.spec.use_gts ? var.instance.spec.gts_private_key != "" : true
    error_message = "gts_private_key is required when use_gts is enabled."
  }
}

variable "instance_name" {
  type    = string
  default = "test_instance"
}

variable "environment" {
  type = any
  default = {
    namespace = "default"
  }
}

variable "inputs" {
  type = any
}
