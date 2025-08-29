# ==============================================================================
# PUSH SUBSCRIPTIONS CONFIGURATION
# ==============================================================================
# This file contains all push subscription related resources and locals

locals {
  # Process push subscriptions configuration
  push_subscriptions_raw = local.spec.push_subscriptions

  # Transform push subscriptions with processed configuration
  push_subscriptions = {
    for name, config in local.push_subscriptions_raw : name => {
      # Basic subscription configuration
      name                         = "${name}-${var.environment.cluster_code}"
      push_endpoint                = config.push_endpoint
      ack_deadline_seconds         = config.ack_deadline_seconds
      message_retention_duration   = config.message_retention_duration
      retain_acked_messages        = config.retain_acked_messages
      filter                       = config.filter
      enable_message_ordering      = config.enable_message_ordering
      enable_exactly_once_delivery = config.enable_exactly_once_delivery

      # OIDC token configuration - Now uses service account email automatically
      oidc_enabled               = lookup(config.oidc_token, "enabled", false)
      oidc_service_account_email = lookup(config.oidc_token, "enabled", false) ? local.service_account_email : null # From service account input
      oidc_audience              = lookup(config.oidc_token, "enabled", false) ? config.oidc_token.audience : null

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

# Create push subscriptions
resource "google_pubsub_subscription" "push" {
  for_each = local.push_subscriptions

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

  # Push configuration
  push_config {
    push_endpoint = each.value.push_endpoint

    # OIDC token configuration (conditional based on enabled flag)
    # Uses service account email from input automatically
    dynamic "oidc_token" {
      for_each = each.value.oidc_enabled ? [1] : []
      content {
        service_account_email = local.service_account_email # From service account input
        audience              = each.value.oidc_audience
      }
    }
  }

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
