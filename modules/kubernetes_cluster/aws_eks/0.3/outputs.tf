locals {
  output_interfaces = {}

  output_attributes = {
    auth = {
      host                   = module.eks.cluster_endpoint
      cluster_ca_certificate = try(kubernetes_secret_v1.facets-admin-token.data["ca.crt"], "na")
      token                  = try(kubernetes_secret_v1.facets-admin-token.data["token"], "na")
    }
    cluster_version         = module.eks.cluster_platform_version
    cluster_name            = local.name
    cluster_arn             = module.eks.cluster_arn
    cluster_id              = module.eks.cluster_id
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
    oidc_provider           = module.eks.oidc_provider
    oidc_provider_arn       = module.eks.oidc_provider_arn
  }
}
