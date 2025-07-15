locals {
  output_interfaces = {}
  output_attributes = {
    policy = aws_iam_policy.iam_policy.policy
    name   = aws_iam_policy.iam_policy.name
    arn    = aws_iam_policy.iam_policy.arn
  }
}
