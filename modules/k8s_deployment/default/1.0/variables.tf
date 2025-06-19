variable "instance" {
  description = "A Terraform module that creates a Kubernetes deployment using the Kubernetes provider"
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      metadata = object({
        name        = string
        namespace   = optional(string, "default")
        labels      = optional(map(string), {})
        annotations = optional(map(string), {})
      })
      spec = object({
        replicas = optional(number, 1)
        selector = optional(object({
          match_labels = optional(map(string), {})
        }), {})
        template = object({
          metadata = optional(object({
            labels      = optional(map(string), {})
            annotations = optional(map(string), {})
          }), {})
          spec = object({
            containers = list(object({
              name  = string
              image = string
              ports = optional(list(object({
                container_port = number
                name           = optional(string)
                protocol       = optional(string, "TCP")
              })), [])
              env = optional(list(object({
                name  = string
                value = string
              })), [])
              resources = optional(object({
                requests = optional(object({
                  cpu    = optional(string, "100m")
                  memory = optional(string, "128Mi")
                }), {})
                limits = optional(object({
                  cpu    = optional(string, "500m")
                  memory = optional(string, "256Mi")
                }), {})
              }), {})
            }))
            restart_policy = optional(string, "Always")
          })
        })
      })
      strategy = optional(object({
        type = optional(string, "RollingUpdate")
        rolling_update = optional(object({
          max_surge       = optional(string, "25%")
          max_unavailable = optional(string, "25%")
        }), {})
      }), {})
    })
  })

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.instance.spec.metadata.name))
    error_message = "Deployment name must be a valid Kubernetes name (lowercase alphanumeric characters and hyphens only)."
  }

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.instance.spec.metadata.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric characters and hyphens only)."
  }

  validation {
    condition     = var.instance.spec.spec.replicas >= 0 && var.instance.spec.spec.replicas <= 1000
    error_message = "Replicas must be between 0 and 1000."
  }

  validation {
    condition     = length(var.instance.spec.spec.template.spec.containers) > 0
    error_message = "At least one container must be specified."
  }

  validation {
    condition = alltrue([
      for container in var.instance.spec.spec.template.spec.containers :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", container.name))
    ])
    error_message = "Container names must be valid Kubernetes names (lowercase alphanumeric characters and hyphens only)."
  }

  validation {
    condition = alltrue([
      for container in var.instance.spec.spec.template.spec.containers :
      alltrue([
        for port in container.ports :
        port.container_port >= 1 && port.container_port <= 65535
      ])
    ])
    error_message = "Container ports must be between 1 and 65535."
  }

  validation {
    condition     = contains(["Always", "OnFailure", "Never"], var.instance.spec.spec.template.spec.restart_policy)
    error_message = "Restart policy must be one of: Always, OnFailure, Never."
  }

  validation {
    condition     = contains(["RollingUpdate", "Recreate"], var.instance.spec.strategy.type)
    error_message = "Strategy type must be either RollingUpdate or Recreate."
  }
}
variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
}
variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = optional(map(string), {})
  })
}
variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
    kubernetes_cluster = object({
      cluster_name           = string
      cluster_endpoint       = string
      cluster_ca_certificate = optional(string)
      namespace              = optional(string)
    })
  })
}
