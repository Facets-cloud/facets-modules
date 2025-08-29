# ==============================================================================
# PUB/SUB TOPIC CONFIGURATION
# ==============================================================================
# This file contains all topic-related resources and locals

locals {
  # Topic-specific configuration
  topic_kms_key_name               = local.spec.topic_kms_key_name
  topic_message_retention_duration = local.spec.topic_message_retention_duration

  # Kinesis ingestion configuration (when enabled) - Now using service account inputs
  kinesis_config = local.kinesis_enabled ? local.spec.kinesis_ingestion : null
}

# Create Pub/Sub topic with optional Kinesis ingestion support
resource "google_pubsub_topic" "this" {
  name    = local.topic_name
  project = local.project_id
  labels  = local.filtered_labels

  # Topic configuration
  kms_key_name               = local.topic_kms_key_name
  message_retention_duration = local.topic_message_retention_duration

  # Kinesis ingestion configuration (only when enabled)
  # Uses service account's AWS role ARN and service account email automatically
  dynamic "ingestion_data_source_settings" {
    for_each = local.kinesis_enabled ? [1] : []
    content {
      aws_kinesis {
        stream_arn          = local.kinesis_config.stream_arn
        consumer_arn        = local.kinesis_config.consumer_arn
        aws_role_arn        = local.aws_role_arn          # From service account input
        gcp_service_account = local.service_account_email # From service account input
      }
    }
  }

  # Schema configuration (only when enabled)
  dynamic "schema_settings" {
    for_each = local.schema_enabled && local.schema_name != null ? [1] : []
    content {
      schema   = google_pubsub_schema.this[0].name
      encoding = local.schema_config.encoding
    }
  }
}
