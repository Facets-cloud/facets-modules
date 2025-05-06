module "alb" {
  depends_on      = [module.eks]
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
