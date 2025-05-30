locals {
  advanced         = lookup(var.instance, "advanced", {})
  advanced_default = lookup(local.advanced, "s3", {})
  enable_bucket_force_ssl = lookup(local.spec, "enable_bucket_force_ssl", false) ? jsonencode(
    {
      policy = {
        statement = [
          {
            Action    = "s3:*",
            Effect    = "Deny",
            Principal = "*",
            Condition = {
              Bool = {
                "aws:SecureTransport" = "false"
              }
            }
          }
        ]
      }
    }
  ) : jsonencode({})
  aws_s3_bucket_policy = merge(lookup(local.advanced_default, "aws_s3_bucket_policy", lookup(local.spec, "aws_s3_bucket_policy", {})), jsondecode(local.enable_bucket_force_ssl))
  spec                 = lookup(var.instance, "spec", {})
  bucket_policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": ${local.statements}
}
EOF
  statements = jsonencode([for item in lookup(lookup(local.aws_s3_bucket_policy, "policy", {}), "statement", []) : merge(item, {
    Resource  = lookup(item, "Resource", [aws_s3_bucket.bucket.arn, "${aws_s3_bucket.bucket.arn}/*"]),
    Condition = lookup(item, "Condition", {}),
    Action    = lookup(item, "Action", ""),
    Effect    = lookup(item, "Effect", ""),
    Principal = lookup(item, "Principal", ""),
    }
  )])
  readonly_iam_policy       = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetLifecycleConfiguration",
                "s3:GetBucketTagging",
                "s3:GetInventoryConfiguration",
                "s3:GetObjectVersionTagging",
                "s3:ListBucketVersions",
                "s3:GetBucketLogging",
                "s3:ListBucket",
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketPolicy",
                "s3:GetObjectVersionTorrent",
                "s3:GetObjectAcl",
                "s3:GetEncryptionConfiguration",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetBucketRequestPayment",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectTagging",
                "s3:GetMetricsConfiguration",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketPolicyStatus",
                "s3:ListBucketMultipartUploads",
                "s3:GetObjectRetention",
                "s3:GetBucketWebsite",
                "s3:GetBucketVersioning",
                "s3:GetBucketAcl",
                "s3:GetObjectLegalHold",
                "s3:GetBucketNotification",
                "s3:GetReplicationConfiguration",
                "s3:ListMultipartUploadParts",
                "s3:GetObject",
                "s3:GetObjectTorrent",
                "s3:GetBucketCORS",
                "s3:GetAnalyticsConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetBucketLocation",
                "s3:GetObjectVersion",
                "s3:RestoreObject",
                "s3:ListObjects"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
            ]
        }
    ]
}
EOF
  readwrite_policy          = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:DeleteObjectTagging",
                "s3:DeleteObjectVersion",
                "s3:DeleteObjectVersionTagging",
                "s3:GetAccelerateConfiguration",
                "s3:GetAnalyticsConfiguration",
                "s3:GetBucketAcl",
                "s3:GetBucketCORS",
                "s3:GetBucketLocation",
                "s3:GetBucketLogging",
                "s3:GetBucketNotification",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetBucketPolicy",
                "s3:GetBucketPolicyStatus",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketRequestPayment",
                "s3:GetBucketTagging",
                "s3:GetBucketVersioning",
                "s3:GetBucketWebsite",
                "s3:GetEncryptionConfiguration",
                "s3:GetInventoryConfiguration",
                "s3:GetLifecycleConfiguration",
                "s3:GetMetricsConfiguration",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectLegalHold",
                "s3:GetObjectRetention",
                "s3:GetObjectTagging",
                "s3:GetObjectTorrent",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectVersionForReplication",
                "s3:GetObjectVersionTagging",
                "s3:GetObjectVersionTorrent",
                "s3:GetReplicationConfiguration",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:ListMultipartUploadParts",
                "s3:PutAccelerateConfiguration",
                "s3:PutAnalyticsConfiguration",
                "s3:PutBucketAcl",
                "s3:PutBucketCORS",
                "s3:PutBucketLogging",
                "s3:PutBucketNotification",
                "s3:PutBucketObjectLockConfiguration",
                "s3:PutBucketPolicy",
                "s3:PutBucketPublicAccessBlock",
                "s3:PutBucketRequestPayment",
                "s3:PutBucketTagging",
                "s3:PutBucketVersioning",
                "s3:PutBucketWebsite",
                "s3:PutEncryptionConfiguration",
                "s3:PutInventoryConfiguration",
                "s3:PutLifecycleConfiguration",
                "s3:PutMetricsConfiguration",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:PutObjectLegalHold",
                "s3:PutObjectRetention",
                "s3:PutObjectTagging",
                "s3:PutObjectVersionAcl",
                "s3:PutObjectVersionTagging",
                "s3:PutReplicationConfiguration",
                "s3:RestoreObject",
                "s3:ListObjects"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
            ]
        }
    ]
}
EOF
  acl                       = lookup(local.advanced_default, "acl", {})
  create_replication_role   = lookup(lookup(local.advanced_default, "replication_configuration", {}), "create_replication_role", false)
  create_replication_policy = lookup(lookup(local.advanced_default, "replication_configuration", {}), "create_replication_policy", false)
  object_ownership          = lookup(local.acl, "object_ownership", "BucketOwnerEnforced")
  block_public_acls         = lookup(local.acl, "block_public_acls", false)
  block_public_policy       = lookup(local.acl, "block_public_policy", false)
  ignore_public_acls        = lookup(local.acl, "ignore_public_acls", false)
  restrict_public_buckets   = lookup(local.acl, "restrict_public_buckets", false)
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_type   = "s3"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 63
}

resource "aws_s3_bucket" "bucket" {
  bucket        = lookup(local.advanced_default, "bucket", module.name.name)
  tags          = merge(var.environment.cloud_tags, lookup(local.advanced_default, "tags", {}))
  force_destroy = lookup(local.advanced_default, "force_destroy", false)
  dynamic "grant" {
    for_each = lookup(local.advanced_default, "grant", {})
    content {
      permissions = lookup(grant.value, "permissions", null)
      type        = lookup(grant.value, "type", null)
      id          = lookup(grant.value, "id", null)
      uri         = lookup(grant.value, "uri", null)
    }
  }
  dynamic "website" {
    for_each = lookup(local.advanced_default, "website", {}) == {} ? {} : { website = lookup(local.advanced_default, "website", {}) }
    content {
      error_document           = lookup(website.value, "error_document", null)
      index_document           = lookup(website.value, "index_document", null)
      redirect_all_requests_to = lookup(website.value, "redirect_all_requests_to", null)
      routing_rules            = lookup(website.value, "routing_rules", null)
    }
  }
  dynamic "cors_rule" {
    for_each = lookup(local.advanced_default, "cors_rule", lookup(local.spec, "cors_rule", {})) == {} ? {} : { cors_rule = lookup(local.advanced_default, "cors_rule", lookup(local.spec, "cors_rule", {})) }
    content {
      allowed_methods = lookup(cors_rule.value, "allowed_methods", null)
      allowed_origins = lookup(cors_rule.value, "allowed_origins", null)
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
  dynamic "versioning" {
    for_each = lookup(local.advanced_default, "versioning", {}) == {} ? {} : { versioning = lookup(local.advanced_default, "versioning", {}) }
    content {
      enabled    = lookup(versioning.value, "enabled", null)
      mfa_delete = lookup(versioning.value, "mfa_delete", null)
    }
  }
  dynamic "logging" {
    for_each = lookup(local.spec, "logging", {})
    content {
      target_bucket = lookup(logging.value, "bucket_name", null)
      target_prefix = lookup(logging.value, "target_prefix", null)
    }
  }
  dynamic "lifecycle_rule" {
    for_each = lookup(local.advanced_default, "lifecycle_rule", lookup(local.spec, "lifecycle_rule", {}))
    content {
      enabled                                = lookup(lifecycle_rule.value, "enabled", true)
      id                                     = lookup(lifecycle_rule.value, "id", lifecycle_rule.key)
      prefix                                 = lookup(lifecycle_rule.value, "prefix", null)
      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)
      dynamic "expiration" {
        for_each = lookup(lifecycle_rule.value, "expiration", null) == null ? [] : [1]
        content {
          date                         = lookup(lifecycle_rule.value.expiration, "date", null)
          days                         = lookup(lifecycle_rule.value.expiration, "days", null)
          expired_object_delete_marker = lookup(lifecycle_rule.value.expiration, "expired_object_delete_marker", null)
        }
      }
      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", null) == null ? [] : [1]
        content {
          storage_class = lookup(lifecycle_rule.value.transition, "storage_class", "STANDARD_IA")
          date          = lookup(lifecycle_rule.value.transition, "date", null)
          days          = lookup(lifecycle_rule.value.transition, "days", null)
        }
      }
      dynamic "noncurrent_version_expiration" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_expiration", null) == null ? [] : [1]
        content {
          days = lookup(lifecycle_rule.value.noncurrent_version_expiration, "days", null)
        }
      }
      dynamic "noncurrent_version_transition" {
        for_each = lookup(local.advanced_default, "noncurrent_version_transition", lookup(lifecycle_rule.value, "noncurrent_version_transition", {})) == {} ? [] : [1]
        content {
          storage_class = lookup(lookup(local.advanced_default, "noncurrent_version_transition", {}), "storage_class", lifecycle_rule.value.noncurrent_version_transition.storage_class)
          days          = lookup(lookup(local.advanced_default, "noncurrent_version_transition", {}), "days", lifecycle_rule.value.noncurrent_version_transition.days)
        }
      }
    }
  }
  acceleration_status = lookup(local.advanced_default, "acceleration_status", null)
  dynamic "server_side_encryption_configuration" {
    for_each = lookup(local.advanced_default, "server_side_encryption_configuration", lookup(local.spec, "server_side_encryption_configuration", { server_side_encryption_configuration = { sse_algorithm = "aws:kms" } }))
    content {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = lookup(server_side_encryption_configuration.value, "sse_algorithm", null)
          kms_master_key_id = lookup(server_side_encryption_configuration.value, "kms_master_key_id", null)
        }
        bucket_key_enabled = lookup(server_side_encryption_configuration.value, "bucket_key_enabled", null)
      }
    }
  }
  dynamic "object_lock_configuration" {
    for_each = lookup(local.advanced_default, "object_lock_configuration", {}) == {} ? {} : { object_lock_configuration = lookup(local.advanced_default, "object_lock_configuration", {}) }
    content {
      object_lock_enabled = lookup(object_lock_configuration.value, "object_lock_enabled", null)
      rule {
        default_retention {
          mode = lookup(object_lock_configuration.value.rule, "default_retention", null)
        }
      }
    }
  }
  dynamic "replication_configuration" {
    for_each = lookup(local.advanced_default, "replication_configuration", null) != null ? [local.advanced_default["replication_configuration"]] : []
    content {
      role = lookup(replication_configuration.value, "role", aws_iam_role.replication_role[0].arn)
      dynamic "rules" {
        for_each = replication_configuration.value.rules
        content {
          status                           = lookup(rules.value, "status", "Enabled")
          delete_marker_replication_status = lookup(rules.value, "delete_marker_replication_status", null)
          id                               = lookup(rules.value, "id", null)
          prefix                           = lookup(rules.value, "prefix", null)
          priority                         = lookup(rules.value, "priority", null)
          dynamic "destination" {
            for_each = lookup(rules.value, "destination", {}) == {} ? {} : { destination = lookup(rules.value, "destination", {}) }
            content {
              bucket             = lookup(destination.value, "bucket", null)
              account_id         = lookup(destination.value, "account_id", null)
              replica_kms_key_id = lookup(destination.value, "replica_kms_key_id", null)
              storage_class      = lookup(destination.value, "storage_class", null)
              dynamic "access_control_translation" {
                for_each = lookup(destination.value, "access_control_translation", {}) == {} ? {} : { access_control_translation = lookup(destination.value, "access_control_translation") }
                content {
                  owner = lookup(access_control_translation.value, "owner", null)
                }
              }
              dynamic "metrics" {
                for_each = lookup(destination.value, "metrics", {}) == {} ? {} : { metrics = lookup(destination.value, "metrics", {}) }
                content {
                  minutes = lookup(metrics.value, "minutes", null)
                  status  = lookup(metrics.value, "status", null)
                }
              }
              dynamic "replication_time" {
                for_each = lookup(destination.value, "replication_time", {}) == {} ? {} : { replication_time = lookup(destination.value, "replication_time", {}) }
                content {
                  minutes = lookup(replication_time.value, "minutes", null)
                  status  = lookup(replication_time.value, "status", null)
                }
              }
            }
          }
          dynamic "filter" {
            for_each = lookup(rules.value, "filter", {}) == {} ? {} : { filter = lookup(rules.value, "filter", {}) }
            content {
              prefix = lookup(filter.value, "prefix", null)
              tags   = lookup(filter.value, "tags", null)
            }
          }
          dynamic "source_selection_criteria" {
            for_each = lookup(rules.value, "source_selection_criteria", {}) == {} ? {} : { source_selection_criteria = lookup(rules.value, "source_selection_criteria", {}) }
            content {
              sse_kms_encrypted_objects {
                enabled = lookup(lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", {}), "enabled", null)
              }
            }
          }
        }
      }
    }
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [bucket, versioning[0].mfa_delete, acl]
  }
}

resource "aws_s3_bucket_policy" "external" {
  depends_on = [aws_s3_bucket_public_access_block.bucket]
  count      = lookup(local.aws_s3_bucket_policy, "policy", {}) != {} ? 1 : 0
  bucket     = aws_s3_bucket.bucket.bucket
  policy     = local.bucket_policy
}

resource "aws_iam_policy" "readonly" {
  name        = "${var.instance_name}-${var.environment.unique_name}-readonly"
  path        = "/"
  description = "${var.instance_name}-${var.environment.unique_name}-readonly"
  tags        = merge(var.environment.cloud_tags, lookup(local.advanced_default, "tags", {}))
  policy      = local.readonly_iam_policy
}

resource "aws_iam_policy" "readwrite" {
  name        = "${var.instance_name}-${var.environment.unique_name}-readwrite"
  path        = "/"
  description = "${var.instance_name}-${var.environment.unique_name}-readwrite"
  tags        = merge(var.environment.cloud_tags, lookup(local.advanced_default, "tags", {}))
  policy      = local.readwrite_policy
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  count  = local.acl == {} ? 0 : 1
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = local.object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  count  = local.acl == {} ? 0 : 1
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = local.block_public_acls
  block_public_policy     = local.block_public_policy
  ignore_public_acls      = local.ignore_public_acls
  restrict_public_buckets = local.restrict_public_buckets
}

resource "aws_iam_role" "replication_role" {
  count = local.create_replication_role ? 1 : 0
  name  = module.role-name.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  count = local.create_replication_policy ? 1 : 0
  name  = "${module.role-name.name}-${var.instance_name}"
  role  = aws_iam_role.replication_role[count.index].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.bucket.arn}/*",
          "${aws_s3_bucket.bucket.arn}"
        ]
      },
      {
        "Action" : [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        "Effect" : "Allow",
        "Condition" : {
          "StringLikeIfExists" : {
            "s3:x-amz-server-side-encryption" : [
              "aws:kms",
              "aws:kms:dsse",
              "AES256"
            ]
          }
        },
        "Resource" : [
          "${local.advanced_default.replication_configuration.rules[0].destination.bucket}/*"
        ]
      },
      {
        Action = ["kms:Decrypt"],
        Effect = "Allow",
        Condition = {
          StringLike = {
            "kms:ViaService" : "s3.${data.aws_region.current.name}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" : "${aws_s3_bucket.bucket.arn}/*"
          }
        },
        Resource = ["${local.advanced_default.replication_configuration.rules[0].source.replica_kms_key_id}"]
      },
      {
        Action = ["kms:Encrypt"],
        Effect = "Allow",
        Condition = {
          StringLike = {
            "kms:ViaService" : "s3.${local.advanced_default.replication_configuration.rules[0].destination.region}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" : "${local.advanced_default.replication_configuration.rules[0].destination.bucket}/*"
          }
        },
        Resource = ["${local.advanced_default.replication_configuration.rules[0].destination.replica_kms_key_id}"]
      }
    ]
  })
}

data "aws_region" "current" {}

module "role-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_name   = "${var.environment.unique_name}-${var.instance_name}"
  resource_type   = "s3"
  limit           = 63 - length("${var.cluster.name}-")
  prefix          = "${var.cluster.name}-"
  environment     = var.environment
}

