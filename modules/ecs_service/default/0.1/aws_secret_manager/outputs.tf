# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    secret_name = aws_secretsmanager_secret.secret-manager-secret.name
    secret_arn  = aws_secretsmanager_secret_version.secret-manager-version.arn
    iam_policies = {
      read_only  = aws_iam_policy.read_only_policy.arn
      read_write = aws_iam_policy.read_write_policy.arn
    }
  }
}
