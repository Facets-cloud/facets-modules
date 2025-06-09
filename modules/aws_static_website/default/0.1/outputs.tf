locals {
  output_attributes = {}
  output_interfaces = merge({
    for domain, domain_details in local.domains : domain => {
      connection_string = "https://${domain_details.domain}",
      host              = domain_details.domain,
      port              = 443
      username          = ""
      password          = ""
      secrets           = []
    }
    }, local.cloudfront_enabled ? {
    "cloudfront" = {
      connection_string = "https://${module.cloudfront.0.cloudfront_distribution_domain_name}",
      host              = module.cloudfront.0.cloudfront_distribution_domain_name,
      port              = 443
      username          = ""
      password          = ""
      secrets           = []
    }
    } : {
    for bucket, bucket_details in local.bucket_names : local.domains != {} ? "bucket-${bucket}" : "default" => {
      connection_string = "http://${module.s3["${bucket}"].website_endpoint}",
      host              = module.s3[bucket].website_endpoint,
      port              = 80
      username          = ""
      password          = ""
      secrets           = []
    }
  })
}
