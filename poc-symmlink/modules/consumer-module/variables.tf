variable "instance_name" {
  description = "Name of the module instance"
  type        = string
}

variable "environment" {
  description = "Environment information"
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = map(string)
  })
}

variable "instance" {
  description = "Instance configuration"
  type = object({
    spec = object({
      string_length   = number
      include_special = bool
      include_upper   = bool
      include_lower   = bool
      include_numeric = bool
    })
  })

  validation {
    condition     = var.instance.spec.string_length >= 1 && var.instance.spec.string_length <= 128
    error_message = "String length must be between 1 and 128 characters."
  }
}

variable "inputs" {
  description = "Inputs from other modules"
  type        = map(any)
  default     = {}
}
