# ==============================================================================
# PUB/SUB SCHEMA CONFIGURATION
# ==============================================================================
# This file contains all schema-related resources and locals

locals {
  # Schema-specific configuration
  schema_config = local.schema_enabled && lookup(local.spec, "schema", null) != null ? local.spec.schema : null

  # Schema name with environment suffix (only when schema is enabled and name is provided)
  schema_name = local.schema_enabled && local.schema_config != null ? lookup(local.schema_config, "name", null) != null ? "${local.schema_config.name}-${var.environment.cluster_code}" : null : null

  # Schema properties
  schema_type       = local.schema_enabled && local.schema_config != null ? lookup(local.schema_config, "type", null) : null
  schema_definition = local.schema_enabled && local.schema_config != null ? lookup(local.schema_config, "definition", null) : null
  schema_encoding   = local.schema_enabled && local.schema_config != null ? lookup(local.schema_config, "encoding", null) : null
}

# Create schema if enabled and configuration is provided
resource "google_pubsub_schema" "this" {
  count = local.schema_enabled && local.schema_name != null && local.schema_definition != null ? 1 : 0

  name       = local.schema_name
  type       = local.schema_type
  definition = local.schema_definition
  project    = local.project_id
}
