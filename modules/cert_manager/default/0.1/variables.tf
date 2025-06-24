variable "instance" {
  type = object({
    spec = object({
      cname_strategy         = string
      disable_dns_validation = optional(bool, false)
      use_gts                = optional(bool, false)
      gts_private_key        = optional(string, "")
      acme_email             = optional(string, "")
      cert_manager = optional(object({
        values = optional(any, {})
      }), {})
    })
  })
  default = {
    spec = {
      cname_strategy         = "Follow"
      disable_dns_validation = false
      use_gts                = false
      gts_private_key        = ""
      acme_email             = ""
      cert_manager           = {}
    }
  }

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
