module "irsa_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 64
  resource_name   = "${var.instance_name}-ec2-ro"
  resource_type   = ""
  is_k8s          = false
  globally_unique = true
}

module "irsa" {
  count  = local.irsa_config.enabled
  source = "github.com/Facets-cloud/facets-utility-modules//aws_irsa"
  iam_arns = {
    ec2_read_only = {
      arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
    }
  }
  iam_role_name         = module.irsa_name.name
  namespace             = var.environment.namespace
  sa_name               = local.irsa_config.service_account_name
  eks_oidc_provider_arn = var.inputs.kubernetes_details.attributes.cluster.oidc_provider_arn
}
