locals {
  output_attributes = {
    table_name        = module.dynamodb.dynamodb_table_id
    table_arn         = module.dynamodb.dynamodb_table_arn
    read_only_policy  = aws_iam_policy.read_only_policy.arn
    read_write_policy = aws_iam_policy.read_write_policy.arn
  }
  output_interfaces = {}
}