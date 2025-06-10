module "dlm-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_name   = "${var.environment.unique_name}-${var.instance_name}"
  resource_type   = "dlm"
  limit           = 30
  environment     = var.environment
}

resource "aws_iam_role" "dlm-role" {
  provider = aws4
  name     = "${module.dlm-name.name}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dlm-policy" {
  provider   = aws4
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
  role       = aws_iam_role.dlm-role.name
}

resource "aws_dlm_lifecycle_policy" "dlm-lifecycle-policy" {
  provider           = aws4
  description        = module.dlm-name.name
  execution_role_arn = aws_iam_role.dlm-role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    dynamic "schedule" {
      for_each = var.instance.spec.schedules
      content {
        name = schedule.key

        create_rule {
          cron_expression = lookup(schedule.value.create_rule, "cron_expression", null)
          interval        = lookup(schedule.value.create_rule, "interval", null)
          interval_unit   = lookup(schedule.value.create_rule, "interval_unit", null)
          times           = lookup(schedule.value.create_rule, "times", null)
        }

        retain_rule {
          count         = lookup(schedule.value.retain_rule, "count", null)
          interval      = lookup(schedule.value.retain_rule, "interval", null)
          interval_unit = lookup(schedule.value.retain_rule, "interval_unit", null)
        }

        tags_to_add = schedule.value.tags_to_add

        copy_tags = schedule.value.copy_tags

        dynamic "cross_region_copy_rule" {
          for_each = lookup(schedule.value, "cross_region_copy_rules", {})
          content {
            target    = lookup(cross_region_copy_rule.value, "target", null)
            encrypted = lookup(cross_region_copy_rule.value, "encrypted", null)
            copy_tags = lookup(cross_region_copy_rule.value, "copy_tags", null)
            retain_rule {
              interval      = lookup(cross_region_copy_rule.value.retain_rule, "interval", null)
              interval_unit = lookup(cross_region_copy_rule.value.retain_rule, "interval_unit", null)
            }
          }
        }
      }
    }

    target_tags = var.instance.spec.target_tags
  }
  tags = merge({
    Name = module.dlm-name.name
  }, var.environment.cloud_tags)
}

locals {
  output_interfaces = {}
  output_attributes = {}
}