module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "kubernetes_cluster"
  globally_unique = true
}

module "k8s_cluster" {
  source        = "./k8s_cluster"
  environment   = var.environment
  vpc_id        = var.inputs.network_details.attributes.vpc_id
  k8s_subnets   = var.inputs.network_details.attributes.private_subnet_ids
  instance      = var.instance
  instance_name = var.instance_name
  cluster       = var.cluster
  cc_metadata   = var.cc_metadata
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
  depends_on = [module.k8s_cluster]
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

provider "kubernetes" {
  host                   = module.k8s_cluster.k8s_details.cluster.auth.host
  cluster_ca_certificate = module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate
  token                  = module.k8s_cluster.k8s_details.cluster.auth.token
}

provider "helm" {
  kubernetes {
    host                   = module.k8s_cluster.k8s_details.cluster.auth.host
    cluster_ca_certificate = module.k8s_cluster.k8s_details.cluster.auth.cluster_ca_certificate
    token                  = module.k8s_cluster.k8s_details.cluster.auth.token
  }
}

resource "helm_release" "secret-copier" {
  depends_on = [module.k8s_cluster]
  count      = lookup(local.secret_copier, "disabled", false) ? 0 : 1
  chart      = lookup(local.secret_copier, "chart", "secret-copier")
  namespace  = lookup(local.secret_copier, "namespace", local.namespace)
  name       = lookup(local.secret_copier, "name", "facets-secret-copier")
  repository = lookup(local.secret_copier, "repository", "https://facets-cloud.github.io/helm-charts")
  version    = lookup(local.secret_copier, "version", "1.0.2")
  values = [
    yamlencode(
      {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "300m"
            memory = "1000Mi"
          }
        }
      }
    ),
    yamlencode(local.user_supplied_helm_values)
  ]
}
