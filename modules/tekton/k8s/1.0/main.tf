locals {
  tekton_dashboard = file("${path.module}/tekton_dashboard.yaml")
  spec = lookup(var.instance, "spec", {})
  namespace = lookup(var.instance, "namespace", "tekton-pipelines"  )
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = true
  globally_unique = false
  resource_type   = "tekton"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 50
}

resource "helm_release" "tekton" {
  name       = module.name.name
  repository = "https://cdfoundation.github.io/tekton-helm-chart"
  chart      = "cdf/tekton-pipeline"
  namespace  = local.namespace
  version    = "2.8.0"
  create_namespace = true
}

module "tekton_dashboard" {
  depends_on = [ helm_release.tekton ]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
  namespace       = local.namespace
  advanced_config = {}
  name            = "${module.name.name}-dashboard"
  resources_data = [
    yamlencode(local.tekton_dashboard)
  ]
}
