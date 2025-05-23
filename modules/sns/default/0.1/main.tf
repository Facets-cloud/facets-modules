module "sns_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 256
  resource_name   = var.instance_name
  resource_type   = "sns"
  globally_unique = false
  is_k8s          = false
}

module "iam_policy_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 119
  resource_name   = var.instance_name
  resource_type   = "sns"
  globally_unique = true
  is_k8s          = false
}

module "sns" {
  source                          = "./terraform-aws-sns-master"
  application_feedback            = local.application_feedback
  archive_policy                  = local.archive_policy
  content_based_deduplication     = local.content_based_deduplication
  create_subscription             = local.create_subscription
  create_topic_policy             = local.create_topic_policy
  data_protection_policy          = local.data_protection_policy
  delivery_policy                 = local.delivery_policy
  display_name                    = module.sns_name.name
  enable_default_topic_policy     = local.enable_default_topic_policy
  fifo_topic                      = local.fifo_topic
  firehose_feedback               = local.firehose_feedback
  http_feedback                   = local.http_feedback
  kms_master_key_id               = local.disable_encryption ? null : local.kms_master_key_id
  lambda_feedback                 = local.lambda_feedback
  name                            = module.sns_name.name
  signature_version               = local.signature_version
  source_topic_policy_documents   = local.source_topic_policy_documents
  sqs_feedback                    = local.sqs_feedback
  tags                            = local.cloud_tags
  topic_policy                    = local.topic_policy
  topic_policy_statements         = local.topic_policy_statements
  tracing_config                  = local.tracing_config
  subscriptions                   = local.subscriptions
  override_topic_policy_documents = local.create_s3_trigger ? [data.aws_iam_policy_document.allow_s3_to_publish[0].json] : local.override_topic_policy_documents
}

resource "aws_iam_policy" "consumer_policy" {
  name   = "${module.iam_policy_name.name}-consumer"
  tags   = local.cloud_tags
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1726720504740",
      "Action": [
        "sns:GetDataProtectionPolicy",
        "sns:GetEndpointAttributes",
        "sns:GetPlatformApplicationAttributes",
        "sns:GetSMSAttributes",
        "sns:GetSMSSandboxAccountStatus",
        "sns:GetSubscriptionAttributes",
        "sns:GetTopicAttributes",
        "sns:ListEndpointsByPlatformApplication",
        "sns:ListOriginationNumbers",
        "sns:ListPhoneNumbersOptedOut",
        "sns:ListPlatformApplications",
        "sns:ListSMSSandboxPhoneNumbers",
        "sns:ListSubscriptions",
        "sns:ListSubscriptionsByTopic",
        "sns:ListTagsForResource",
        "sns:ListTopics"
      ],
      "Effect": "Allow",
      "Resource": "${module.sns.topic_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "producer_policy" {
  name   = "${module.iam_policy_name.name}-producer"
  tags   = local.cloud_tags
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1726721019737",
      "Action": "sns:*",
      "Effect": "Allow",
      "Resource": "${module.sns.topic_arn}"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = local.create_s3_trigger ? 1 : 0
  bucket = local.s3_name

  topic {
    topic_arn = module.sns.topic_arn
    events    = local.s3_events
    filter_prefix = local.s3_filter_prefix
    filter_suffix = local.s3_filter_suffix
  }
}
data "aws_iam_policy_document" "allow_s3_to_publish" {
  count = local.create_s3_trigger ? 1 : 0
  statement {
    sid    = "AllowS3ToPublishToSNS"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:*:*:${module.sns_name.name}"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.s3_arn]
    }
  }
  override_policy_documents = local.override_topic_policy_documents # allow what's in json to override this.
}

