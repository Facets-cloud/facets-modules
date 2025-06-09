locals {
  spec                         = lookup(var.instance, "spec", {})
  website                      = lookup(local.spec, "website", {})
  advanced                     = lookup(var.instance, "advanced", {})
  s3_key                       = lookup(local.website, "source_code_s3_path", null)
  acm_certificate_arn          = lookup(local.website, "acm_certificate_arn", null)
  dir_name                     = module.name.name
  domains                      = lookup(var.instance.spec, "domains", {})
  bucket_names = local.domains == {} || local.cloudfront_enabled ? {
    (module.s3name.name) : {
      "bucket" : module.s3name.name
    }
    } : {
    for domain, domain_details in local.domains : (domain) => {
      "bucket" = domain_details.domain
    }
  }
  cloudfront_enabled  = lookup(local.website, "cloudfront_enabled", true)
  s3_advanced         = lookup(local.advanced, "s3", {})
  cloudfront_advanced = lookup(local.advanced, "cloudfront", {})
  website_advanced    = lookup(local.advanced, "website", {})
  allow_public_access_acl = {
    "block_public_acls"       = false,
    "block_public_policy"     = false,
    "ignore_public_acls"      = false,
    "restrict_public_buckets" = false
  }
  public_read_acces_bucket_policy = <<EOF
{
    "Version": "2012-10-17",
    "statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ]
        }
    ]
}
EOF

  s3_details_cdn_enabled = local.cloudfront_enabled ? { (module.s3name.name) = merge({
    "bucket" = module.s3name.name
  }, local.s3_advanced) } : {}

  s3_details_cdn_disabled = local.cloudfront_enabled ? {} : { for bucket, bucket_details in local.bucket_names : bucket => merge({
    "bucket" = bucket_details.bucket,
    "aws_s3_bucket_policy" = {
      "policy" = jsondecode(local.public_read_acces_bucket_policy)
    },
    "website" = {
      "index_document"           = lookup(local.website_advanced, "index_document", "index.html"),
      "error_document"           = lookup(local.website_advanced, "error_document", "error.html")
    },
    "acl" : local.allow_public_access_acl
  }, local.s3_advanced) }

  s3_details = merge(local.s3_details_cdn_enabled, local.s3_details_cdn_disabled)

  cloudfront_aliases = local.cloudfront_enabled ? { for domain, domain_details in local.domains : domain => domain_details.domain } : {}

  cloudfront_details = local.cloudfront_enabled ? {
    "spec" = {
      "aliases" = local.cloudfront_aliases,
      "viewer_certificate" = {
        "acm_certificate_arn" = local.acm_certificate_arn
      },
      "origins" = {
        "origin" = {
          "domain_name" = module.s3[module.s3name.name].bucket_regional_domain_name
        }
      },
      "default_cache_behavior" = merge(lookup(local.cloudfront_advanced, "default_cache_behavior", {
        "target_origin_id" = "origin",
        "allowed_methods" = [
          "DELETE",
          "GET",
          "HEAD",
          "OPTIONS",
          "PATCH",
          "POST",
          "PUT"
        ],
        "cached_methods" = [
          "GET",
          "HEAD"
        ],
        "viewer_protocol_policy" = "allow-all"
        }),
        {
          "target_origin_id" = "origin"
      })
    },
    "advanced" = {
      "cloudfront" = merge({
        "default_root_object" = lookup(local.website_advanced, "index_document", "index.html")
      }, local.cloudfront_advanced)
    }
  } : null
}
