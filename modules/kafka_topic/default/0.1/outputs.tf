# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    topics = [for topic_name, topic_details in local.topics : topic_name]
  }
}
