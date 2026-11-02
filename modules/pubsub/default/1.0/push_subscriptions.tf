# ==============================================================================
# PUSH SUBSCRIPTIONS CONFIGURATION - SIMPLIFIED
# ==============================================================================
# This file contains simplified push subscription resources

locals {
  # Process push subscriptions configuration - simplified
  push_subscriptions_raw = local.spec.push_subscriptions

  # Transform push subscriptions with basic configuration only
  push_subscriptions = {
    for name, config in local.push_subscriptions_raw : name => {
      # Basic subscription configuration
      name                 = "${name}-${var.environment.cluster_code}"
      push_endpoint        = config.push_endpoint
      ack_deadline_seconds = config.ack_deadline_seconds
    }
  }
}

# Create push subscriptions - uses environment's default project
resource "google_pubsub_subscription" "push" {
  for_each = local.push_subscriptions

  name   = each.value.name
  topic  = google_pubsub_topic.this.name
  labels = local.filtered_labels

  # Basic subscription configuration only
  ack_deadline_seconds = each.value.ack_deadline_seconds

  # Push configuration - basic only
  push_config {
    push_endpoint = each.value.push_endpoint
    # No OIDC authentication in simplified version
  }

  # No project specified - uses default from provider/environment  
  # Removed: message retention, filters, ordering, dead letter, retry policies
}
