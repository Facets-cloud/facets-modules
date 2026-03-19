data "aws_region" "current" {}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 48
  resource_name   = var.instance_name
  resource_type   = "ack_acm_controller"
  globally_unique = true
}

locals {
  name                       = module.name.name
  controller_namespace       = coalesce(lookup(var.instance.spec, "namespace", null), var.environment.namespace)
  controller_service_account = "ack-acm-controller"
  eks_oidc_provider_arn      = try(var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.oidc_provider_arn, var.baseinfra.k8s_details.oidc_provider_arn)
  aws_region                 = data.aws_region.current.name

  # Tolerations: merge environment defaults with facets dedicated tolerations
  tolerations = concat(
    lookup(var.environment, "default_tolerations", []),
    try(var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations, [])
  )

  # Node selector from kubernetes_details legacy outputs
  node_selector = try(var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_node_selectors, {})

  controller_tolerations = [
    for taint in local.tolerations : {
      key      = taint.key
      operator = "Equal"
      value    = lookup(taint, "value", "")
      effect   = taint.effect
    }
  ]
}

# IAM Policy for ACK ACM Controller
resource "aws_iam_policy" "ack_acm" {
  name        = "${local.name}-ack-acm"
  description = "IAM policy for the ACK ACM Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "acm:AddTagsToCertificate",
          "acm:RemoveTagsFromCertificate"
        ]
        Resource = "*"
      }
    ]
  })
}

# IRSA - IAM Role for Service Account
module "irsa" {
  source                = "github.com/Facets-cloud/facets-utility-modules//aws_irsa"
  eks_oidc_provider_arn = local.eks_oidc_provider_arn
  iam_role_name         = local.name
  namespace             = local.controller_namespace
  sa_name               = local.controller_service_account
  iam_arns = {
    (local.controller_service_account) = {
      arn = aws_iam_policy.ack_acm.arn
    }
  }
}

# Deploy ACK ACM Controller via Helm
resource "helm_release" "ack_acm" {
  namespace        = local.controller_namespace
  create_namespace = true
  name             = "ack-acm-controller"
  repository       = "oci://public.ecr.aws/aws-controllers-k8s"
  chart            = "acm-chart"
  version          = var.instance.spec.chart_version
  wait             = true
  timeout          = 600

  values = [
    yamlencode(merge({
      aws = {
        region = local.aws_region
      }
      serviceAccount = {
        create = true
        name   = local.controller_service_account
        annotations = {
          "eks.amazonaws.com/role-arn" = module.irsa.iam_role_arn
        }
      }
      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
      nodeSelector = local.node_selector
      tolerations  = local.controller_tolerations
      installScope = "cluster"
    }, lookup(var.instance.spec, "helm_values", {})))
  ]

  depends_on = [
    module.irsa
  ]
}
