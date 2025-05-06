

module "alb" {
  depends_on      = [data.aws_eks_cluster.cluster]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-alb"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-alb"
  data            = local.alb_data
  advanced_config = {}
}

module "ingress_class" {
  depends_on      = [data.aws_eks_cluster.cluster]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-fc-alb-ig-class"
  namespace       = var.environment.namespace
  release_name    = "${local.name}-fc-alb-ig-class"
  advanced_config = {}
  data            = local.alb_ig_class_data
}