locals {
  # Use specified location or fallback to environment region
  # Using lookup to safely handle cases where location may not be present
  location = lookup(var.instance.spec, "location", var.environment.region)

  # Generate bucket name within GCS 63-character limit
  # Format: [env_unique_name]-[instance_name]
  # Ensure compliance with GCS naming rules: lowercase letters, numbers, hyphens
  base_name = "${var.environment.unique_name}-${var.instance_name}"

  # Convert to lowercase and replace invalid characters with hyphens
  sanitized_name = lower(replace(local.base_name, "/[^a-z0-9-]/", "-"))

  # Ensure the name is not longer than 63 characters (GCS bucket name limit)
  # If it would be too long, truncate it but keep the environment prefix and ensure uniqueness
  bucket_name = length(local.sanitized_name) <= 63 ? local.sanitized_name : (
    "${substr(var.environment.unique_name, 0, 20)}-${substr(var.instance_name, 0, 30)}-${random_id.suffix[0].hex}"
  )
}

# Create a random suffix to use if the name would be too long
resource "random_id" "suffix" {
  count       = 1
  byte_length = 4
}

resource "google_storage_bucket" "bucket" {
  name          = local.bucket_name
  location      = local.location
  storage_class = var.instance.spec.storage_class
  project       = var.inputs.cloud_account.attributes.project

  uniform_bucket_level_access = var.instance.spec.uniform_bucket_level_access
  requester_pays              = var.instance.spec.requester_pays

  versioning {
    enabled = var.instance.spec.versioning_enabled
  }

  # Only add lifecycle rule if enabled
  dynamic "lifecycle_rule" {
    for_each = var.instance.spec.lifecycle_rules.enabled ? [1] : []
    content {
      condition {
        age = var.instance.spec.lifecycle_rules.age_days
      }
      action {
        type = var.instance.spec.lifecycle_rules.action
        # Only add storage_class if action is SetStorageClass
        storage_class = var.instance.spec.lifecycle_rules.action == "SetStorageClass" ? var.instance.spec.lifecycle_rules.storage_class : null
      }
    }
  }

  # Labels
  labels = merge(
    var.environment.cloud_tags,
    var.instance.spec.custom_labels
  )

  # Force destroy for easier cleanup in testing
  force_destroy = true

  # Ensure we don't create invalid bucket names
  lifecycle {
    precondition {
      condition     = length(local.bucket_name) <= 63
      error_message = "The GCS bucket name must be less than 63 characters."
    }
  }
}