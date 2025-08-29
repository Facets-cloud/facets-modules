locals {
  output_attributes = {
    id                      = google_pubsub_topic.this.id
    name                    = google_pubsub_topic.this.name
    labels                  = local.filtered_labels
    topic_full_name         = google_pubsub_topic.this.name
    pull_subscription_names = { for k, v in google_pubsub_subscription.pull : k => v.name }
    push_subscription_names = { for k, v in google_pubsub_subscription.push : k => v.name }
  }
  output_interfaces = {
  }
}