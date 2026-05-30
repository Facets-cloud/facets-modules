# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    cloudfront_distribution_arn                = module.cloudfront.cloudfront_distribution_arn
    cloudfront_distribution_domain_name        = module.cloudfront.cloudfront_distribution_domain_name
    cloudfront_distribution_etag               = module.cloudfront.cloudfront_distribution_etag
    cloudfront_distribution_id                 = module.cloudfront.cloudfront_distribution_id
    cloudfront_distribution_last_modified_time = module.cloudfront.cloudfront_distribution_last_modified_time
    cloudfront_origin_access_identities = {
      for k, v in module.cloudfront.cloudfront_origin_access_identities : k => v.iam_arn
    }
  }
}

# For testing
output "cloudfront_distribution_arn" {
  value = module.cloudfront.cloudfront_distribution_arn
}

output "cloudfront_distribution_caller_reference" {
  value = module.cloudfront.cloudfront_distribution_caller_reference
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_etag" {
  value = module.cloudfront.cloudfront_distribution_etag
}

output "cloudfront_distribution_hosted_zone_id" {
  value = module.cloudfront.cloudfront_distribution_hosted_zone_id
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_in_progress_validation_batches" {
  value = module.cloudfront.cloudfront_distribution_in_progress_validation_batches
}

output "cloudfront_distribution_last_modified_time" {
  value = module.cloudfront.cloudfront_distribution_last_modified_time
}

output "cloudfront_distribution_status" {
  value = module.cloudfront.cloudfront_distribution_status
}


output "cloudfront_distribution_tags" {
  value = module.cloudfront.cloudfront_distribution_tags
}


output "cloudfront_distribution_trusted_signers" {
  value = module.cloudfront.cloudfront_distribution_trusted_signers
}


output "cloudfront_monitoring_subscription_id" {
  value = module.cloudfront.cloudfront_monitoring_subscription_id
}


output "cloudfront_origin_access_identities" {
  value = module.cloudfront.cloudfront_origin_access_identities
}

output "cloudfront_origin_access_identity_iam_arns" {
  value = module.cloudfront.cloudfront_origin_access_identity_iam_arns
}

output "cloudfront_origin_access_identity_ids" {
  value = module.cloudfront.cloudfront_origin_access_identity_ids
}
