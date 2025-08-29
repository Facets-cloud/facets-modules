# ==============================================================================
# PULL SUBSCRIPTIONS CONFIGURATION
# ==============================================================================
# This file contains all pull subscription related resources and locals

locals {
  # Process pull subscriptions configuration
  pull_subscriptions_raw = local.spec.pull_subscriptions

  # Transform pull subscriptions with processed configuration
  pull_subscriptions = {
    for name, config in local.pull_subscriptions_raw : name => {
      # Basic subscription configuration
      name                         = "${name}-${var.environment.cluster_code}"
      ack_deadline_seconds         = config.ack_deadline_seconds
      message_retention_duration   = config.message_retention_duration
      retain_acked_messages        = config.retain_acked_messages
      filter                       = config.filter
      enable_message_ordering      = config.enable_message_ordering
      enable_exactly_once_delivery = config.enable_exactly_once_delivery

      # Dead letter policy configuration
      dead_letter_enabled   = lookup(config.dead_letter_policy, "enabled", false)
      dead_letter_topic     = lookup(config.dead_letter_policy, "enabled", false) ? config.dead_letter_policy.dead_letter_topic : null
      max_delivery_attempts = lookup(config.dead_letter_policy, "enabled", false) ? config.dead_letter_policy.max_delivery_attempts : null

      # Retry policy configuration
      retry_enabled   = lookup(config.retry_policy, "enabled", false)
      minimum_backoff = lookup(config.retry_policy, "enabled", false) ? config.retry_policy.minimum_backoff : null
      maximum_backoff = lookup(config.retry_policy, "enabled", false) ? config.retry_policy.maximum_backoff : null
    }
  }
}

# Create pull subscriptions
resource "google_pubsub_subscription" "pull" {
  for_each = local.pull_subscriptions

  name    = each.value.name
  topic   = google_pubsub_topic.this.name
  project = local.project_id
  labels  = local.filtered_labels

  # Basic subscription configuration
  ack_deadline_seconds         = each.value.ack_deadline_seconds
  message_retention_duration   = each.value.message_retention_duration
  retain_acked_messages        = each.value.retain_acked_messages
  filter                       = each.value.filter
  enable_message_ordering      = each.value.enable_message_ordering
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery

  # Dead letter policy (conditional based on enabled flag)
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_enabled && each.value.dead_letter_topic != null ? [1] : []
    content {
      dead_letter_topic     = each.value.dead_letter_topic
      max_delivery_attempts = each.value.max_delivery_attempts
    }
  }

  # Retry policy (conditional based on enabled flag)
  dynamic "retry_policy" {
    for_each = each.value.retry_enabled && each.value.minimum_backoff != null ? [1] : []
    content {
      minimum_backoff = each.value.minimum_backoff
      maximum_backoff = each.value.maximum_backoff
    }
  }
}
