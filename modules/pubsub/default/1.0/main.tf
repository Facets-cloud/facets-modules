# ==============================================================================
# SHARED LOCALS AND COMMON CONFIGURATION
# ==============================================================================
# This file contains shared locals that are used across multiple resource files

locals {
  # Basic configuration - Now from service account input
  project_id   = var.inputs.service_account.attributes.outputs_project.attributes.project_id
  project_name = var.inputs.service_account.attributes.outputs_project.attributes.project_name
  spec         = var.instance.spec

  # Service account details from input
  service_account_email = var.inputs.service_account.attributes.email
  aws_role_arn          = var.inputs.service_account.attributes.aws_role_arn

  # Generate topic name from instance_name and cluster_code
  topic_name = "${var.instance_name}-${var.environment.cluster_code}"

  # Convert tags object to GCP labels format with proper filtering
  standardized_labels = {
    purpose            = var.instance.spec.tags.purpose
    costgroup          = var.instance.spec.tags.costgroup
    group              = var.instance.spec.tags.group
    environment        = var.environment.name
    owner              = var.instance.spec.tags.owner
    securitylevel      = var.instance.spec.tags.securitylevel
    lifecycle          = var.instance.spec.tags.lifecycle
    compliancegroup    = lookup(var.instance.spec.tags, "compliancegroup", null)
    billing            = lookup(var.instance.spec.tags, "billing", null)
    workstream         = lookup(var.instance.spec.tags, "workstream", null)
    sharedresource     = lookup(var.instance.spec.tags, "sharedresource", null)
    merchant           = lookup(var.instance.spec.tags, "merchant", null)
    dataclassification = var.instance.spec.tags.dataclassification
    rplproject         = local.project_id
  }

  # Filter out null, empty string, or unspecified values
  filtered_labels = {
    for k, v in local.standardized_labels : k => v
    if v != null && v != ""
  }

  # Global feature flags
  kinesis_enabled = lookup(local.spec, "kinesis_ingestion", null) != null ? lookup(local.spec.kinesis_ingestion, "enabled", false) : false
  schema_enabled  = lookup(local.spec, "schema", null) != null ? lookup(local.spec.schema, "enabled", false) : false
}
