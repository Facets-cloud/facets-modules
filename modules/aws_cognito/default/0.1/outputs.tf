locals {
  output_interfaces = {}
  output_attributes = {
    name                                   = module.aws-cognito.name
    arn                                    = module.aws-cognito.arn
    client_ids_map                         = module.aws-cognito.client_ids_map
    client_secrets_map                     = module.aws-cognito.client_secrets_map
    endpoint                               = module.aws-cognito.endpoint
    client_ids                             = module.aws-cognito.client_ids
    client_secrets                         = module.aws-cognito.client_secrets
    creation_date                          = module.aws-cognito.creation_date
    domain_app_version                     = module.aws-cognito.domain_app_version
    domain_aws_account_id                  = module.aws-cognito.domain_aws_account_id
    domain_cloudfront_distribution         = module.aws-cognito.domain_cloudfront_distribution
    domain_cloudfront_distribution_arn     = module.aws-cognito.domain_cloudfront_distribution_arn
    domain_cloudfront_distribution_zone_id = module.aws-cognito.domain_cloudfront_distribution_zone_id
    domain_s3_bucket                       = module.aws-cognito.domain_s3_bucket
    id                                     = module.aws-cognito.id
    last_modified_date                     = module.aws-cognito.last_modified_date
    resource_servers_scope_identifiers     = module.aws-cognito.resource_servers_scope_identifiers
    secrets                                = ["client_secrets_map", "client_secrets"]
  }
}
