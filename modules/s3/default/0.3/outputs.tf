locals {
  output_interfaces = {}
  output_attributes = {
    bucket_name               = aws_s3_bucket.bucket.bucket
    bucket_arn                = aws_s3_bucket.bucket.arn
    read_only_iam_policy_arn  = aws_iam_policy.readonly.arn
    read_write_iam_policy_arn = aws_iam_policy.readwrite.arn
    bucket_region             = aws_s3_bucket.bucket.region
  }
}
