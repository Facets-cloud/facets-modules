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
        equivalent_prefixes   = optional(list(string), [])
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
      # Capillary-specific fields
      custom_log_format      = optional(string)
      log_format_escape      = optional(string, "default")
      underscores_in_headers = optional(bool, false)
      ip_access_control = optional(object({
        deny  = optional(list(string), [])
        allow = optional(list(string), [])
      }))
      proxy_buffer_size    = optional(string)
      proxy_buffers_number = optional(number)
      proxy_set_headers    = optional(map(string), {})
      dns_override = optional(object({
        record_type  = optional(string)
        record_value = optional(string)
      }))
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
