variable "instance" {
  description = "A fully-managed real-time messaging service for Google Cloud that enables message exchange between independent applications with support for AWS Kinesis Data Streams ingestion."
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      tags = object({
        purpose            = string
        costgroup          = string
        group              = string
        owner              = string
        securitylevel      = string
        lifecycle          = string
        compliancegroup    = optional(string, null)
        billing            = optional(string, null)
        workstream         = optional(string, null)
        sharedresource     = optional(bool, null)
        merchant           = optional(string, null)
        dataclassification = string
      })

      # Topic Configuration
      topic_kms_key_name               = optional(string, null)
      topic_message_retention_duration = optional(string, "604800s")

      # AWS Kinesis Ingestion - Now fully automatic
      kinesis_ingestion = optional(object({
        enabled      = optional(bool, false)
        stream_arn   = optional(string, null)
        consumer_arn = optional(string, null)
      }), {})

      # Schema Configuration
      schema = optional(object({
        enabled    = optional(bool, false)
        name       = optional(string, null)
        type       = optional(string, "AVRO")
        definition = optional(string, null)
        encoding   = optional(string, "JSON")
      }), {})

      # Pull Subscriptions
      pull_subscriptions = optional(map(object({
        ack_deadline_seconds         = optional(number, 20)
        message_retention_duration   = optional(string, "604800s")
        retain_acked_messages        = optional(bool, false)
        filter                       = optional(string, null)
        enable_message_ordering      = optional(bool, false)
        enable_exactly_once_delivery = optional(bool, false)
        dead_letter_policy = optional(object({
          enabled               = optional(bool, false)
          dead_letter_topic     = optional(string, null)
          max_delivery_attempts = optional(number, 5)
        }), {})
        retry_policy = optional(object({
          enabled         = optional(bool, false)
          minimum_backoff = optional(string, "10s")
          maximum_backoff = optional(string, "600s")
        }), {})
      })), {})

      # Push Subscriptions - Simplified OIDC token config
      push_subscriptions = optional(map(object({
        push_endpoint                = string
        ack_deadline_seconds         = optional(number, 20)
        message_retention_duration   = optional(string, "604800s")
        retain_acked_messages        = optional(bool, false)
        filter                       = optional(string, null)
        enable_message_ordering      = optional(bool, false)
        enable_exactly_once_delivery = optional(bool, false)
        oidc_token = optional(object({
          enabled  = optional(bool, false)
          audience = optional(string, null)
        }), {})
        dead_letter_policy = optional(object({
          enabled               = optional(bool, false)
          dead_letter_topic     = optional(string, null)
          max_delivery_attempts = optional(number, 5)
        }), {})
        retry_policy = optional(object({
          enabled         = optional(bool, false)
          minimum_backoff = optional(string, "10s")
          maximum_backoff = optional(string, "600s")
        }), {})
      })), {})
    })
  })

  # Standardized tags validation
  validation {
    condition = alltrue([
      var.instance.spec.tags.purpose != null && var.instance.spec.tags.purpose != "",
      var.instance.spec.tags.costgroup != null && var.instance.spec.tags.costgroup != "",
      var.instance.spec.tags.group != null && var.instance.spec.tags.group != "",
      var.instance.spec.tags.owner != null && var.instance.spec.tags.owner != "",
      var.instance.spec.tags.securitylevel != null && var.instance.spec.tags.securitylevel != "",
      var.instance.spec.tags.lifecycle != null && var.instance.spec.tags.lifecycle != "",
      var.instance.spec.tags.dataclassification != null && var.instance.spec.tags.dataclassification != ""
    ])
    error_message = "All required tags (purpose, costgroup, group, owner, securitylevel, lifecycle, dataclassification) must be provided and cannot be empty."
  }

  # Kinesis ingestion validation - Simplified
  validation {
    condition = var.instance.spec.kinesis_ingestion == null || !var.instance.spec.kinesis_ingestion.enabled || (
      var.instance.spec.kinesis_ingestion.stream_arn != null &&
      var.instance.spec.kinesis_ingestion.consumer_arn != null
    )
    error_message = "When Kinesis ingestion is enabled, stream_arn and consumer_arn must be provided."
  }

  validation {
    condition = var.instance.spec.kinesis_ingestion == null || !var.instance.spec.kinesis_ingestion.enabled || (
      var.instance.spec.kinesis_ingestion.stream_arn != null &&
      can(regex("^arn:aws:kinesis:[^:]+:[^:]+:stream/.+", var.instance.spec.kinesis_ingestion.stream_arn))
    )
    error_message = "Kinesis stream_arn must be in the format: arn:aws:kinesis:region:account:stream/stream-name"
  }

  # Schema validation
  validation {
    condition = var.instance.spec.schema == null || !var.instance.spec.schema.enabled || (
      var.instance.spec.schema.name != null &&
      var.instance.spec.schema.definition != null
    )
    error_message = "When schema validation is enabled, both schema name and definition must be provided."
  }

  validation {
    condition = var.instance.spec.schema == null || !var.instance.spec.schema.enabled || (
      contains(["AVRO", "PROTOCOL_BUFFER"], var.instance.spec.schema.type)
    )
    error_message = "Schema type must be either 'AVRO' or 'PROTOCOL_BUFFER'."
  }

  validation {
    condition = var.instance.spec.schema == null || !var.instance.spec.schema.enabled || (
      contains(["JSON", "BINARY"], var.instance.spec.schema.encoding)
    )
    error_message = "Schema encoding must be either 'JSON' or 'BINARY'."
  }

  # Pull subscription validations
  validation {
    condition = alltrue([
      for sub_name, sub_config in var.instance.spec.pull_subscriptions :
      sub_config.ack_deadline_seconds >= 10 && sub_config.ack_deadline_seconds <= 600
    ])
    error_message = "Pull subscription ack_deadline_seconds must be between 10 and 600 seconds."
  }

  validation {
    condition = alltrue([
      for sub_name, sub_config in var.instance.spec.pull_subscriptions :
      sub_config.dead_letter_policy == null || !sub_config.dead_letter_policy.enabled || (
        sub_config.dead_letter_policy.dead_letter_topic != null &&
        sub_config.dead_letter_policy.max_delivery_attempts >= 5 &&
        sub_config.dead_letter_policy.max_delivery_attempts <= 100
      )
    ])
    error_message = "Pull subscription dead letter policy, when enabled, must have a topic and max_delivery_attempts between 5 and 100."
  }

  # Push subscription validations
  validation {
    condition = alltrue([
      for sub_name, sub_config in var.instance.spec.push_subscriptions :
      sub_config.ack_deadline_seconds >= 10 && sub_config.ack_deadline_seconds <= 600
    ])
    error_message = "Push subscription ack_deadline_seconds must be between 10 and 600 seconds."
  }

  validation {
    condition = alltrue([
      for sub_name, sub_config in var.instance.spec.push_subscriptions :
      sub_config.dead_letter_policy == null || !sub_config.dead_letter_policy.enabled || (
        sub_config.dead_letter_policy.dead_letter_topic != null &&
        sub_config.dead_letter_policy.max_delivery_attempts >= 5 &&
        sub_config.dead_letter_policy.max_delivery_attempts <= 100
      )
    ])
    error_message = "Push subscription dead letter policy, when enabled, must have a topic and max_delivery_attempts between 5 and 100."
  }

  # OIDC token validation - Simplified (no service account email needed)
  validation {
    condition = alltrue([
      for sub_name, sub_config in var.instance.spec.push_subscriptions :
      sub_config.oidc_token == null || !sub_config.oidc_token.enabled || (
        sub_config.oidc_token.audience != null
      )
    ])
    error_message = "Push subscription OIDC token, when enabled, must have audience specified."
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

variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
    service_account = object({
      attributes = object({
        email          = string
        aws_role_arn   = string
        aws_role_name  = string
        default_labels = map(string)
        outputs_project = object({
          attributes = object({
            project_id    = string
            project_name  = string
            instance_name = string
          })
        })
      })
    })
  })
}
