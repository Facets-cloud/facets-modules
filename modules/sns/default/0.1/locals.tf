locals {
  advanced     = lookup(lookup(var.instance, "advanced", {}), "default", {})
  advanced_sns = lookup(local.advanced, "sns", {})
  metadata     = lookup(var.instance, "metadata", {})
  cloud_tags   = merge(var.environment.cloud_tags, lookup(local.metadata, "tags", {}))
  spec         = lookup(var.instance, "spec", {})


  application_feedback            = lookup(local.spec, "application_feedback", lookup(local.advanced_sns, "application_feedback", {}))
  archive_policy                  = lookup(local.spec, "archive_policy", null) != null ? jsonencode(local.spec.archive_policy) : lookup(local.advanced_sns, "archive_policy", null)
  content_based_deduplication     = lookup(local.spec, "content_based_deduplication", lookup(local.advanced_sns, "content_based_deduplication", false))
  create_subscription             = lookup(local.spec, "create_subscription", lookup(local.advanced_sns, "create_subscription", true))
  create_topic_policy             = lookup(local.spec, "create_topic_policy", lookup(local.advanced_sns, "create_topic_policy", true))
  data_protection_policy          = lookup(local.spec, "data_protection_policy", lookup(local.advanced_sns, "data_protection_policy", null))
  delivery_policy                 = lookup(local.spec, "delivery_policy", null) != null ? jsonencode(local.spec.delivery_policy) : lookup(local.advanced_sns, "delivery_policy", null)
  enable_default_topic_policy     = lookup(local.spec, "enable_default_topic_policy", lookup(local.advanced_sns, "enable_default_topic_policy", true))
  fifo_topic                      = lookup(local.spec, "fifo_topic", lookup(local.advanced_sns, "fifo_topic", false))
  firehose_feedback               = lookup(local.spec, "firehose_feedback", lookup(local.advanced_sns, "firehose_feedback", {}))
  http_feedback                   = lookup(local.spec, "http_feedback", lookup(local.advanced_sns, "http_feedback", {}))
  kms_master_key_id               = lookup(local.spec, "kms_master_key_id", lookup(local.advanced_sns, "kms_master_key_id", "alias/aws/sns"))
  lambda_feedback                 = lookup(local.spec, "lambda_feedback", lookup(local.advanced_sns, "lambda_feedback", {}))
  signature_version               = lookup(local.spec, "signature_version", lookup(local.advanced_sns, "signature_version", null))
  source_topic_policy_documents   = [for statement in lookup(local.spec, "source_topic_policy_documents", lookup(local.advanced_sns, "source_topic_policy_documents", [])) : jsonencode(statement)]
  sqs_feedback                    = lookup(local.spec, "sqs_feedback", lookup(local.advanced_sns, "sqs_feedback", {}))
  topic_policy                    = jsonencode(lookup(local.spec, "topic_policy", lookup(local.advanced_sns, "topic_policy", {})))
  topic_policy_statements         = [for statement in(lookup(local.spec, "topic_policy_statements", lookup(local.advanced_sns, "topic_policy_statements", {}))) : jsonencode(statement)]
  tracing_config                  = lookup(local.spec, "tracing_config", lookup(local.advanced_sns, "tracing_config", null))
  override_topic_policy_documents = [for statement in lookup(local.spec, "override_topic_policy_documents", lookup(local.advanced_sns, "override_topic_policy_documents", [])) : jsonencode(statement)]


  disable_encryption = lookup(local.spec, "disable_encryption", false)

  subscriptions = lookup(local.spec, "subscriptions", {})

  triggers          = lookup(local.spec, "triggers", {})
  s3_triggers       = lookup(local.triggers, "s3", {})
  create_s3_trigger = length(local.s3_triggers) != 0
  s3_name           = lookup(local.s3_triggers, "name", null)
  s3_arn            = lookup(local.s3_triggers, "arn", null)
  s3_events         = lookup(local.s3_triggers, "events", [])
  s3_filter_prefix  = lookup(local.s3_triggers, "filter_prefix", null)
  s3_filter_suffix  = lookup(local.s3_triggers, "filter_suffix", null)
}
