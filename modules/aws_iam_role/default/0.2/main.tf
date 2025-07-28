# Define your terraform resources here
module "aws_iam_role_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = local.name
  resource_type   = "aws_iam_role"
  limit           = 50
  environment     = var.environment
}


module "iam_eks_role" {
  count            = length(local.irsa) > 0 ? 1 : 0
  source           = "github.com/Facets-cloud/facets-utility-modules//aws_irsa/iam-role-for-service-accounts-eks"
  role_name        = module.aws_iam_role_name.name
  role_policy_arns = { for k, v in local.policies : k => v.arn }
  oidc_providers   = local.oidc_providers
  tags             = merge(local.user_defined_tags, var.environment.cloud_tags)
}
