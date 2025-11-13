# ==============================================================================
# SHARED LOCALS AND COMMON CONFIGURATION
# ==============================================================================
# This file contains shared locals that are used across multiple resource files

locals {
  # Use project ID from cloud account input if available, otherwise use default provider project
  project_id = try(var.inputs.cloud_account.project, null) # Let Terraform use the default project from provider/environment if cloud_account not provided
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
