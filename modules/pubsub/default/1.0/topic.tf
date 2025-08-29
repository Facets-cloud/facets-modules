# ==============================================================================
# PUB/SUB TOPIC CONFIGURATION
# ==============================================================================
# This file contains all topic-related resources and locals

locals {
  # Topic-specific configuration - simplified
  topic_message_retention_duration = local.spec.topic_message_retention_duration
}

# Create Pub/Sub topic - uses environment's default project
resource "google_pubsub_topic" "this" {
  name   = local.topic_name
  labels = local.filtered_labels

  # Topic configuration
  message_retention_duration = local.topic_message_retention_duration

  # No project specified - uses default from provider/environment
  # No schema support in basic version
  # No KMS encryption in basic version
}
