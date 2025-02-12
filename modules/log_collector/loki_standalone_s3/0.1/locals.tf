locals {
  sa_name = lower(module.name.name)

  spec   = lookup(var.instance, "spec", {})
  aws_s3 = lookup(local.spec, "aws_s3", {})


  loki            = lookup(local.spec, "loki", {})
  loki_namespace  = lookup(local.loki, "namespace", "facets")
  loki_standalone = lookup(local.loki, "loki_standalone", {})
  loki_config     = lookup(local.loki_standalone, "values", {})


  // Bucket name for chunk and ruler
  chunk_bucket_name = lookup(lookup(local.aws_s3, "bucket_names", {}), "chunks", null)
  ruler_bucket_name = lookup(lookup(local.aws_s3, "bucket_names", {}), "ruler", null)

  //Promtail
  promtail_helm_values = lookup(lookup(local.spec, "promtail", {}), "values", {})
  promtail_values      = lookup(local.spec, "promtail", {})

  readwrite_policy = <<EOF
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
                "s3:RestoreObject"
            ],
            "Resource": [
                "arn:aws:s3:::${local.chunk_bucket_name}",
                "arn:aws:s3:::${local.chunk_bucket_name}/*",
                "arn:aws:s3:::${local.ruler_bucket_name}",
                "arn:aws:s3:::${local.ruler_bucket_name}/*"
            ]
        }
    ]
}
EOF

  loki_s3_default_values = {
    serviceAccount = merge({
      create = true
      name   = local.sa_name
      annotations = {
        "eks.amazonaws.com/role-arn" = module.irsa.iam_role_arn
      }
      },
      lookup(lookup(local.loki_standalone, "values", {}), "serviceAccount", {})
    )
    loki = merge({
      ## https://grafana.com/docs/loki/latest/setup/install/helm/deployment-guides/aws/#loki-helm-chart-configuration
      storage = {
        type = "s3"
        bucketNames = {
          chunks = local.chunk_bucket_name
          ruler  = local.ruler_bucket_name
        }
        s3 = {
          region           = var.cluster.awsRegion
          s3ForcePathStyle = false
          insecure         = false
        }
      }
      },
      lookup(lookup(local.loki_standalone, "values", {}), "loki", {})
    )
  }


  log_collector_promtail = {
    #    promtail = {
    #      promtail_config = {
    #        values = local.promtail_config_values
    #      }
    #      values = local.promtail_values
    #    }
  }

  merged_loki_standalone_values = merge(
    local.loki_config,
    local.loki_s3_default_values
  )
  log_collector = {
    flavor = var.instance.flavor
    spec = {
      loki = {
        replicas = local.spec.loki.replicas
        volume   = local.spec.loki.volume
        loki_standalone = merge(
          local.loki_standalone,
          {
          values = local.merged_loki_standalone_values
        }
        )
      }
      promtail = local.promtail_values
    }
  }
  #  log_collector_loki = {
  #    loki-standalone = merge(
  #      local.loki_helm,
  #      {
  #        values = merge(
  #          local.loki,
  #          {
  #            serviceAccount = {
  #              create = true
  #              name   = local.sa_name
  #              annotations = {
  #                "eks.amazonaws.com/role-arn" = module.irsa.iam_role_arn
  #              }
  #            }
  #            loki = {
  #              ## https://grafana.com/docs/loki/latest/setup/install/helm/deployment-guides/aws/#loki-helm-chart-configuration
  #              storage = {
  #                type = "s3"
  #                bucketNames = {
  #                  chunks = local.chunk_bucket_name
  #                  ruler  = local.ruler_bucket_name
  #                }
  #                s3 = {
  #                  region           = var.cluster.awsRegion
  #                  s3ForcePathStyle = false
  #                  insecure         = false
  #                }
  #              }
  #            }
  #          }
  #        )
  #      }
  #    )
  #  }
  #
  #  log_collector_promtail = {
  #    promtail = merge(
  #      local.promtail_helm,
  #      {
  #        values = lookup(local.promtail_helm, "values", {})
  #      }
  #    )
  #  }
  #
  #  log_collector = {
  #    flavor = var.instance.flavor
  #    spec   = local.spec
  #    advanced = {
  #      loki = merge(
  #        local.log_collector_loki,
  #        local.log_collector_promtail
  #      )
  #    }
  #  }
}