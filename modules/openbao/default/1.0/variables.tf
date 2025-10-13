# Standard Facets module variables
variable "instance_name" {
  description = "The unique name for this module instance"
  type        = string
}

variable "instance" {
  description = "The instance configuration"
  type = object({
    kind    = string
    flavor  = string
    version = string
    metadata = optional(object({
      namespace = optional(string, "default")
    }), {})
    spec = object({
      namespace       = optional(string, "default")
      release_name    = optional(string, "openbao")
      chart_version   = optional(string, "0.18.4")
      server_replicas = optional(number, 1)
      server_resources = optional(object({
        requests = optional(object({
          cpu    = optional(string, "500m")
          memory = optional(string, "256Mi")
        }), {})
        limits = optional(object({
          cpu    = optional(string, "1000m")
          memory = optional(string, "512Mi")
        }), {})
      }), {})
      ui_enabled             = optional(bool, true)
      storage_type           = optional(string, "raft")
      storage_size           = optional(string, "10Gi")
      pvc_labels             = optional(map(string), {})
      controlplane_sa_name   = optional(string, "control-plane-service-sa")
      facets_release_sa_name = optional(string, "facets-release-pod")
      openbao = optional(object({
        values = optional(map(any), {})
      }), {})
    })
  })

  validation {
    condition     = var.instance.spec.server_replicas >= 1 && var.instance.spec.server_replicas <= 10
    error_message = "Server replicas must be between 1 and 10."
  }

  validation {
    condition     = contains(["file", "raft"], var.instance.spec.storage_type)
    error_message = "Storage type must be one of: file, raft."
  }

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.instance.spec.namespace))
    error_message = "Namespace must match pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
  }

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.instance.spec.release_name))
    error_message = "Release name must match pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
  }
}

variable "environment" {
  description = "Environment configuration"
  type = object({
    unique_name = string
    cloud_tags  = map(string)
  })
}

variable "inputs" {
  description = "Inputs from other modules"
  type        = map(any)
  default     = {}
}
