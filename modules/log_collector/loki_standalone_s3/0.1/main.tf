resource "aws_iam_policy" "readwrite" {
  name        = "${module.name.name}-readwrite"
  path        = "/"
  description = "${module.name.name}-readwrite"
  tags        = var.environment.cloud_tags
  policy      = local.readwrite_policy
}

module "irsa" {
  source = "../../3_utility/aws_irsa"
  iam_arns = {
    s3_read_write_access = {
      arn = aws_iam_policy.readwrite.arn
    }
  }
  iam_role_name         = "${local.sa_name}-service-role"
  namespace             = local.loki_namespace
  sa_name               = local.sa_name
  eks_oidc_provider_arn = try(var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.oidc_provider_arn, var.baseinfra.k8s_details.oidc_provider_arn)
}

module "name" {
  source          = "../../3_utility/name"
  environment     = var.environment
  limit           = 63
  resource_name   = var.instance_name
  resource_type   = "log-collector"
  is_k8s          = true
  globally_unique = false
}

module "log_collector" {
  source = "../log_collector_standalone"

  instance      = local.log_collector
  instance_name = lower(var.instance_name)
  environment   = var.environment
  cluster       = var.cluster
  baseinfra     = var.baseinfra
  cc_metadata   = var.cc_metadata
  #  inputs        = var.inputs
  #  providers = {
  #    aws.tooling = aws.tooling
  #  }
}
