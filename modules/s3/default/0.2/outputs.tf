locals {
  output_attributes = {
    bucket_name               = aws_s3_bucket.bucket.bucket
    bucket_arn                = aws_s3_bucket.bucket.arn
    read_only_iam_policy_arn  = aws_iam_policy.readonly.arn
    read_write_iam_policy_arn = aws_iam_policy.readwrite.arn
    bucket_region             = aws_s3_bucket.bucket.region
  }
  output_interfaces = {}
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

output "iam_policies" {
  value = {
    READ_ONLY  = aws_iam_policy.readonly.arn
    READ_WRITE = aws_iam_policy.readwrite.arn
  }
}

output "bucket_region" {
  value = aws_s3_bucket.bucket.region
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "website_endpoint" {
  value = aws_s3_bucket.bucket.website_endpoint
}