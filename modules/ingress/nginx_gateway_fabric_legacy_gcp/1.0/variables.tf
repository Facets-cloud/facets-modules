variable "cluster" {
  type    = any
  default = {}
}

variable "baseinfra" {
  type    = any
  default = {}
}

variable "cc_metadata" {
  type = any
  default = {
    tenant_base_domain = "tenant.facets.cloud"
  }
}

variable "instance" {
  type = object({
    spec = object({
      private             = optional(bool, false)
      disable_base_domain = optional(bool, false)
      domains = optional(map(object({
        domain                = string
        alias                 = string
        certificate_reference = optional(string)
      })), {})
      data_plane             = optional(any)
      control_plane          = optional(any)
      rules                  = optional(any, {})
      force_ssl_redirection  = optional(bool, false)
      basic_auth             = optional(bool, false)
      body_size              = optional(string, "150m")
      helm_values            = optional(any, {})
      domain_prefix_override = optional(string)
      helm_wait              = optional(bool, true)
      use_dns01              = optional(bool, false)
      dns01_cluster_issuer   = optional(string, "gts-production")
    })
  })
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
  type    = any
  default = {}
}
