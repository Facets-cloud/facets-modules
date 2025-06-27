# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    secret_name = aws_secretsmanager_secret.secret-manager-secret.name
    secret_arn  = aws_secretsmanager_secret_version.secret-manager-version.arn
  }
}
