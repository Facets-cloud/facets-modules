module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "kubernetes_cluster"
  globally_unique = true
}

module "eks" {
  source                                   = "./aws-terraform-eks"
  cluster_name                             = "${substr(var.cluster.name, 0, 38 - 11 - 12)}-${var.cluster.clusterCode}-k8s-cluster"
  cluster_compute_config                   = local.cluster_compute_config
  cluster_version                          = local.kubernetes_version
  cluster_endpoint_public_access           = local.cluster_endpoint_public_access
  cluster_endpoint_private_access          = local.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs     = local.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = true
  cluster_enabled_log_types                = local.cluster_enabled_log_types
  vpc_id                                   = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  subnet_ids                               = var.inputs.network_details.attributes.legacy_outputs.vpc_details.k8s_subnets
  cluster_security_group_additional_rules  = local.cluster_security_group_additional_rules
  cloudwatch_log_group_retention_in_days   = local.cloudwatch_log_group_retention_in_days
  cluster_service_ipv4_cidr                = local.cluster_service_ipv4_cidr
  tags                                     = local.tags
}

resource "kubernetes_storage_class" "eks-auto-mode-gp3" {
  depends_on = [ module.eks ]
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
  depends_on      = [module.eks]
  count           = lookup(local.default_node_pool, "enabled", true) ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-default-np"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-default-np"
  data            = local.default_node_pool_data
  advanced_config = {}
}

module "dedicated_node_pool" {
  depends_on      = [module.eks]
  count           = lookup(local.dedicated_node_pool, "enabled", false) ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-dedicated-np"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-dedicated-np"
  data            = local.dedicated_node_pool_data
  advanced_config = {}

}

resource "aws_eks_addon" "addon" {
  provider                 = "aws593"
  depends_on               = [
    module.eks, module.default_node_pool, module.dedicated_node_pool
  ]
  for_each                 = local.addons
  cluster_name             = module.eks.cluster_name
  addon_name               = each.key
  addon_version            = each.value["addon_version"]
  configuration_values     = each.value["configuration_values"]
  resolve_conflicts        = each.value["resolve_conflicts"]
  tags                     = each.value["tags"]
  preserve                 = each.value["preserve"]
  service_account_role_arn = each.value["service_account_role_arn"]

  lifecycle {
    prevent_destroy = true
  }
}
