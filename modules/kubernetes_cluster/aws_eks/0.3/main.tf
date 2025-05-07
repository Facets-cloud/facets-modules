module "k8s_cluster" {
  source        = "./k8s_cluster"
  environment   = var.environment
  inputs        = var.inputs
  instance      = var.instance
  instance_name = var.instance_name
  cluster       = var.cluster
}

module "alb" {
  depends_on      = [module.k8s_cluster]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "alb"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-alb"
  data            = local.alb_data
  advanced_config = {}
}

module "ingress_class" {
  depends_on      = [module.alb]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "alb"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-alb-ig-class"
  advanced_config = {}
  data            = local.ingress_class_data
}


resource "kubernetes_storage_class" "eks-auto-mode-gp3" {
  depends_on = [module.eks, kubernetes_cluster_role_binding.facets-admin-crb]
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
  depends_on      = [module.eks, kubernetes_cluster_role_binding.facets-admin-crb]
  count           = lookup(local.default_node_pool, "enabled", true) ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-default-np"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-default-np"
  data            = local.default_node_pool_data
  advanced_config = {}
}

module "dedicated_node_pool" {
  depends_on      = [module.eks, kubernetes_cluster_role_binding.facets-admin-crb]
  count           = lookup(local.dedicated_node_pool, "enabled", false) ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-dedicated-np"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-dedicated-np"
  data            = local.dedicated_node_pool_data
  advanced_config = {}
}


provider "kubernetes" {
  host                   = module.k8s_cluster.k8s_details.auth.host
  cluster_ca_certificate = module.k8s_cluster.k8s_details.auth.cluster_ca_certificate
  token                  = module.k8s_cluster.k8s_details.auth.token
}

provider "helm" {
  kubernetes {
    host                   = module.k8s_cluster.k8s_details.auth.host
    cluster_ca_certificate = module.k8s_cluster.k8s_details.auth.cluster_ca_certificate
    token                  = module.k8s_cluster.k8s_details.auth.token
  }
}
