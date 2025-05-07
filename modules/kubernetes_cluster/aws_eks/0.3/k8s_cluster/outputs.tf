output "k8s_details" {
  value = {
    auth = {
      host                   = module.eks.cluster_endpoint
      cluster_ca_certificate = try(kubernetes_secret_v1.facets-admin-token.data["ca.crt"], "na")
      token                  = try(kubernetes_secret_v1.facets-admin-token.data["token"], "na")
    }
    cluster_version         = module.eks.cluster_platform_version
    cluster_name            = "${substr(var.cluster.name, 0, 38 - 11 - 12)}-${var.cluster.clusterCode}-k8s-cluster"
    cluster_arn             = module.eks.cluster_arn
    cluster_id              = module.eks.cluster_name
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
    oidc_provider           = module.eks.oidc_provider
    oidc_provider_arn       = module.eks.oidc_provider_arn
    legacy_outputs = {
      registry_secret_objects         = []
      facets_dedicated_tolerations    = []
      facets_dedicated_node_selectors = {}
      k8s_details = {
        auth = {
          host                   = module.eks.cluster_endpoint
          cluster_ca_certificate = try(kubernetes_secret_v1.facets-admin-token.data["ca.crt"], "na")
          token                  = try(kubernetes_secret_v1.facets-admin-token.data["token"], "na")
        }
        oidc_provider_arn        = module.eks.oidc_provider_arn
        cluster_id               = module.eks.cluster_name
        cluster_oidc_issuer_url  = module.eks.cluster_oidc_issuer_url
        node_group_iam_role_arn  = ""
        node_group_iam_role_name = ""
        worker_nodes_secgrp      = ""
      }
      aws_cloud = {
        region = var.cluster.awsRegion
      }
    }
  }
}
