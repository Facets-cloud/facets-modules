variable "instance" {
  description = "A fully-managed real-time messaging service for Google Cloud that enables message exchange between independent applications."
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      # Topic Configuration
      topic_name                       = optional(string, "my-topic")
      topic_message_retention_duration = optional(string, "604800s")

      # Pull Subscriptions (simplified)
      pull_subscriptions = optional(map(object({
        ack_deadline_seconds = optional(number, 20)
      })), {})

      # Push Subscriptions (simplified)
      push_subscriptions = optional(map(object({
        push_endpoint        = string
        ack_deadline_seconds = optional(number, 20)
      })), {})
    })
  })

  # Pull subscription validations
  validation {
    condition = alltrue([
      for sub_name, sub_config in var.instance.spec.pull_subscriptions :
      sub_config.ack_deadline_seconds >= 10 && sub_config.ack_deadline_seconds <= 600
    ])
    error_message = "Pull subscription ack_deadline_seconds must be between 10 and 600 seconds."
  }

  # Push subscription validations
  validation {
    condition = alltrue([
      for sub_name, sub_config in var.instance.spec.push_subscriptions :
      sub_config.ack_deadline_seconds >= 10 && sub_config.ack_deadline_seconds <= 600
    ])
    error_message = "Push subscription ack_deadline_seconds must be between 10 and 600 seconds."
  }
}

variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
}

variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name         = string
    unique_name  = string
    cloud_tags   = map(string)
    cluster_code = string
  })
}

# Note: This is a placeholder variable to satisfy validation requirements
# This module no longer uses inputs but the validation system expects it
variable "inputs" {
  description = "Placeholder inputs variable - not used by this standalone module."
  type        = map(any)
  default     = {}
}
