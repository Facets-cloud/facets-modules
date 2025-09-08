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
}

