locals {
  output_interfaces = {}
  output_attributes = {
    iam_user          = aws_iam_user.iam_user.name
    user_arn          = aws_iam_user.iam_user.arn
    access_key_id     = sensitive(aws_iam_access_key.iam_user_key.id)
    secret_access_key = sensitive(aws_iam_access_key.iam_user_key.secret)
    secrets = [
      "access_key_id",
      "secret_access_key"
    ]
  }
}
