module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "kubernetes_cluster"
  globally_unique = true
}

module "eks" {
  source = "./eks"
  cluster_name                             = local.name
  cluster_version                          = local.kubernetes_version
  cluster_endpoint_public_access           = local.cluster_endpoint_public_access
  cluster_endpoint_private_access          = local.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs     = local.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = true
  cluster_enabled_log_types                = local.cluster_enabled_log_types
  vpc_id                                   = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  subnet_ids                               = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_ids
  cluster_security_group_additional_rules  = local.cluster_security_group_additional_rules
  cloudwatch_log_group_retention_in_days   = local.cloudwatch_log_group_retention_in_days
  cluster_service_ipv4_cidr                = local.cluster_service_ipv4_cidr
  tags                                     = local.tags
}

resource "kubernetes_storage_class" "eks-auto-mode-gp3" {
  depends_on = [
    module.eks, data.aws_eks_cluster.cluster, data.aws_eks_cluster_auth.cluster
  ]
  metadata {
    name = "eks-auto-mode-gp3-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.eks.amazonaws.com"
  reclaim_policy      = local.default_reclaim_policy
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
  allow_volume_expansion = true
  volume_binding_mode    = "Immediate"
}

module "default_node_pool" {
  source       = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name         = "${local.name}-default-node-pool"
  namespace    = var.environment.namespace
  release_name = "${local.name}-default-node-pool"
  data         = local.default_node_pool
}

module "dedicated_node_pool" {
  source       = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name         = "${local.name}-dedicated-node-pool"
  namespace    = var.environment.namespace
  release_name = "${local.name}-dedicated-node-pool"
  data         = local.dedicated_node_pool
}
