resource "random_string" "suffix" {
  length  = 1
  special = "false"
  upper   = "false"
}

# Define your terraform resources here
module "secret_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_name   = "${var.instance_name}${random_string.suffix.result}"
  resource_type   = "aws_secret_manager"
  limit           = 60
  environment     = var.environment
}

resource "aws_secretsmanager_secret" "secret-manager-secret" {
  name                    = local.override_default_name ? local.override_name : module.secret_name.name
  description             = lookup(local.advanced, "description", null)
  kms_key_id              = lookup(local.advanced, "kms_key_id", null)
  recovery_window_in_days = lookup(local.advanced, "recovery_window_in_days", null)
  tags                    = merge(local.user_defined_tags, var.environment.cloud_tags)
  lifecycle {
    prevent_destroy = false
    ignore_changes = [name]
  }
}

resource "aws_iam_policy" "read_only_policy" {
  name        = "${module.secret_name.name}-read-only"
  description = "Read-only access to the secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.secret-manager-secret.arn
      }
    ]
  })
}

resource "aws_iam_policy" "read_write_policy" {
  name        = "${module.secret_name.name}-read-write"
  description = "Read-write access to the secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue"
        ]
        Resource = aws_secretsmanager_secret.secret-manager-secret.arn
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "secret-manager-version" {
  secret_id     = aws_secretsmanager_secret.secret-manager-secret.id
  secret_string = jsonencode(local.secrets)
}
