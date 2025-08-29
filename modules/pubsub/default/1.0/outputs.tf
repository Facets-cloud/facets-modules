locals {
  output_attributes = {
    id                        = google_pubsub_topic.this.id
    name                      = google_pubsub_topic.this.name
    project_id                = local.project_id
    topic_full_name           = google_pubsub_topic.this.name
    kinesis_ingestion_enabled = local.kinesis_enabled
    schema_enabled            = local.schema_enabled
    schema_name               = local.schema_enabled && local.schema_name != null ? google_pubsub_schema.this[0].name : null
    pull_subscription_names   = { for k, v in google_pubsub_subscription.pull : k => v.name }
    push_subscription_names   = { for k, v in google_pubsub_subscription.push : k => v.name }
    labels                    = local.filtered_labels
  }
  output_interfaces = {
  }
}