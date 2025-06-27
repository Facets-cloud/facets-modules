locals {
  output_attributes = {
    cluster_issuer_dns  = local.use_gts ? "gts-production" : "letsencrypt-prod"
    cluster_issuer_http = local.use_gts ? "gts-production-http01" : "letsencrypt-prod-http01"
    use_gts             = local.use_gts
    namespace           = local.cert_mgr_namespace
  }
  output_interfaces = {
  }
}