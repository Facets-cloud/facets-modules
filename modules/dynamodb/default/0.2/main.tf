
locals {
  spec         = var.instance.spec
  aws_dynamodb = lookup(lookup(var.instance, "advanced", {}), "aws_dynamodb", {})

  attributes = [
    for attribute in local.spec.attributes :
    {
      name = attribute.name
      type = attribute.type
    }
  ]

  tags = merge(var.environment.cloud_tags, lookup(local.aws_dynamodb, "tags", {}))
}

module "dynamodb" {
  source = "./terraform-aws-dynamodb-table-2.0.0"

  name                               = "${var.instance_name}-${var.environment.name}"
  attributes                         = local.attributes
  hash_key                           = local.spec.hash_key
  autoscaling_defaults               = lookup(local.aws_dynamodb, "autoscaling_defaults", { "scale_in_cooldown" : 0, "scale_out_cooldown" : 0, "target_value" : 70 })
  autoscaling_enabled                = lookup(local.aws_dynamodb, "autoscaling_enabled", false)
  autoscaling_indexes                = lookup(local.aws_dynamodb, "autoscaling_indexes", {})
  autoscaling_read                   = lookup(local.aws_dynamodb, "autoscaling_read", {})
  autoscaling_write                  = lookup(local.aws_dynamodb, "autoscaling_write", {})
  billing_mode                       = lookup(local.aws_dynamodb, "billing_mode", "PAY_PER_REQUEST")
  create_table                       = lookup(local.aws_dynamodb, "create_table", true)
  global_secondary_indexes           = lookup(local.aws_dynamodb, "global_secondary_indexes", [])
  local_secondary_indexes            = lookup(local.aws_dynamodb, "local_secondary_indexes", [])
  point_in_time_recovery_enabled     = lookup(local.aws_dynamodb, "point_in_time_recovery_enabled", false)
  range_key                          = lookup(local.aws_dynamodb, "range_key", null)
  read_capacity                      = lookup(local.aws_dynamodb, "read_capacity", null)
  replica_regions                    = lookup(local.aws_dynamodb, "replica_regions", [])
  server_side_encryption_enabled     = lookup(local.aws_dynamodb, "server_side_encryption_enabled", false)
  server_side_encryption_kms_key_arn = lookup(local.aws_dynamodb, "server_side_encryption_kms_key_arn", null)
  stream_enabled                     = lookup(local.aws_dynamodb, "stream_enabled", false)
  stream_view_type                   = lookup(local.aws_dynamodb, "stream_view_type", null)
  table_class                        = lookup(local.aws_dynamodb, "table_class", null)
  tags                               = local.tags
  timeouts                           = lookup(local.aws_dynamodb, "timeouts", { "create" : "10m", "delete" : "10m", "update" : "60m" })
  ttl_attribute_name                 = lookup(local.aws_dynamodb, "ttl_attribute_name", "")
  ttl_enabled                        = lookup(local.aws_dynamodb, "ttl_enabled", false)
  write_capacity                     = lookup(local.aws_dynamodb, "write_capacity", null)
}

resource "aws_iam_policy" "read_only_policy" {
  name   = "${var.environment.name}-${module.dynamodb.dynamodb_table_id}_ro"
  tags   = var.environment.cloud_tags
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListAndDescribe",
            "Effect": "Allow",
            "Action": [
                "dynamodb:List*",
                "dynamodb:DescribeReservedCapacity*",
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeTimeToLive"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SpecificTable",
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGet*",
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:Get*",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": ["${module.dynamodb.dynamodb_table_arn}", "${module.dynamodb.dynamodb_table_arn}/index/*"]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "read_write_policy" {
  name   = "${var.environment.name}-${module.dynamodb.dynamodb_table_id}_rw"
  tags   = var.environment.cloud_tags
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListAndDescribe",
            "Effect": "Allow",
            "Action": [
                "dynamodb:List*",
                "dynamodb:DescribeReservedCapacity*",
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeTimeToLive"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SpecificTable",
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGet*",
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:Get*",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchWrite*",
                "dynamodb:CreateTable",
                "dynamodb:Delete*",
                "dynamodb:Update*",
                "dynamodb:PutItem"
            ],
            "Resource": ["${module.dynamodb.dynamodb_table_arn}", "${module.dynamodb.dynamodb_table_arn}/index/*"]
        }
    ]
}
EOF

}
