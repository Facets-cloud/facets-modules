# ==============================================================================
# PULL SUBSCRIPTIONS CONFIGURATION - SIMPLIFIED
# ==============================================================================
# This file contains simplified pull subscription resources

locals {
  # Process pull subscriptions configuration - simplified
  pull_subscriptions_raw = local.spec.pull_subscriptions

  # Transform pull subscriptions with basic configuration only
  pull_subscriptions = {
    for name, config in local.pull_subscriptions_raw : name => {
      # Basic subscription configuration
      name                 = "${name}-${var.environment.cluster_code}"
      ack_deadline_seconds = config.ack_deadline_seconds
    }
  }
}

# Create pull subscriptions - uses environment's default project
resource "google_pubsub_subscription" "pull" {
  for_each = local.pull_subscriptions

  name   = each.value.name
  topic  = google_pubsub_topic.this.name
  labels = local.filtered_labels

  # Basic subscription configuration only
  ack_deadline_seconds = each.value.ack_deadline_seconds

  # No project specified - uses default from provider/environment
  # Removed: message retention, filters, ordering, dead letter, retry policies
}
