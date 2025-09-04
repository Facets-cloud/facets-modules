# ==============================================================================
# SHARED LOCALS AND COMMON CONFIGURATION
# ==============================================================================
# This file contains shared locals that are used across multiple resource files

locals {
  # Use environment's project automatically - no user input needed
  project_id = null # Let Terraform use the default project from provider/environment
  spec       = var.instance.spec

  # Generate topic name from user input and cluster_code
  topic_name = "${var.instance.spec.topic_name}-${var.environment.cluster_code}"

  # Simple labels using only environment cloud tags and basic info
  filtered_labels = merge(
    var.environment.cloud_tags,
    {
      environment   = var.environment.name
      instance_name = var.instance_name
    }
  )

  # Global feature flags - simplified (no schema support in basic version)
  schema_enabled = false
}
