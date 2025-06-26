variable "instance" {
  type = object({
    spec = object({
      version          = string
      namespace        = string
      create_namespace = bool
      deployment = object({
        cleanup_on_fail = bool
        wait            = bool
        atomic          = bool
        timeout         = number
        recreate_pods   = bool
      })
      recommender = object({
        enabled = bool
        storage = optional(string)
        size = object({
          cpu           = string
          memory        = string
          cpu_limits    = string
          memory_limits = string
        })
        configuration = optional(map(any))
      })
      updater = object({
        enabled = bool
      })
      admission_controller = object({
        enabled = bool
      })
      helm_values = optional(map(any))
    })
  })

  validation {
    condition     = contains(["prometheus", "memory"], var.instance.spec.recommender.storage != null ? var.instance.spec.recommender.storage : "prometheus")
    error_message = "recommender.storage must be either 'prometheus' or 'memory'."
  }

  validation {
    condition     = var.instance.spec.deployment.timeout >= 60 && var.instance.spec.deployment.timeout <= 3600
    error_message = "deployment.timeout must be between 60 and 3600 seconds."
  }
}

variable "instance_name" {
  type    = string
  default = "test_instance"
}

variable "environment" {
  type = any
  default = {
    namespace           = "default"
    default_tolerations = []
    cloud_tags          = {}
  }
}

variable "inputs" {
  type = any
}