
resource "aws_iam_role" "eventbridge" {
  name = module.name.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
  tags = merge(var.environment.cloud_tags, lookup(local.spec, "tags", {}))
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_type   = "aws_eventbridge"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 20
}

data "aws_iam_policy_document" "eb_kms_key_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eb_kms_key_policy" {
  name        = module.name.name
  description = "Policy for allowing EventBridge to use KMS keys"
  policy      = data.aws_iam_policy_document.eb_kms_key_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_eb_kms_key_policy" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eb_kms_key_policy.arn
}
