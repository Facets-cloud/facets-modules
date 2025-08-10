output "k8s_details" {
  value = {
    cluster = {
      auth = {
        host                   = module.eks.cluster_endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      }
      name              = data.aws_eks_cluster.cluster.name
      version           = module.eks.cluster_version
      arn               = module.eks.cluster_arn
      id                = module.eks.cluster_id
      oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
      oidc_provider     = module.eks.oidc_provider
      oidc_provider_arn = module.eks.oidc_provider_arn
    }
    node_group = {
      iam_role_arn      = module.eks.node_iam_role_arn
      iam_role_name     = module.eks.node_iam_role_name
      security_group_id = module.eks.node_security_group_id
    }
  }
}

output "legacy_outputs" {
  value = {
    registry_secret_objects         = []
    facets_dedicated_tolerations    = []
    facets_dedicated_node_selectors = {}
    k8s_details = {
      auth = {
        host                   = module.eks.cluster_endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      }
      cluster_name             = data.aws_eks_cluster.cluster.name
      eks_auto_mode_enabled    = true
      oidc_provider_arn        = module.eks.oidc_provider_arn
      cluster_id               = module.eks.cluster_id
      cluster_oidc_issuer_url  = module.eks.cluster_oidc_issuer_url
      cluster_version          = module.eks.cluster_version
      node_group_iam_role_arn  = module.eks.node_iam_role_arn
      node_group_iam_role_name = module.eks.node_iam_role_name
      worker_nodes_secgrp      = module.eks.node_security_group_id
    }
    aws_cloud = {
      region = var.cluster.awsRegion
    }
  }
}
