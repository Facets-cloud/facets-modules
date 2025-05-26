locals {
  constructed_helm_values = {
    serviceMutatorWebhookConfig = {
      failurePolicy = "Ignore"
    }
    clusterName = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_id
    rbac = {
      create = true
    }
    serviceAccount = {
      create = true
      name   = "facets-aws-alb-ingress-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.aws_alb_controller[0].arn
      }
    }
    tolerations  = concat(var.environment.default_tolerations, var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations)
    nodeSelector = var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_node_selectors
    defaultTags  = var.environment.cloud_tags
  }
  spec                         = lookup(var.instance, "spec", {})
  advanced                     = lookup(var.instance, "advanced", {})
  aws-load-balancer-controller = lookup(local.spec, "aws_alb_controller", lookup(local.advanced, "aws_alb_controller", {}))
  user_defined_helm_values     = lookup(local.aws-load-balancer-controller, "values", {})
}
resource "aws_iam_policy" "aws_alb_controller" {
  count       = 1
  name        = "${substr(var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_name, 0, 128 - 11 - 19)}-ingress-iam-policy"
  path        = "/"
  description = "Policy for alb-ingress service"

  policy = data.aws_iam_policy_document.aws_alb_controller[0].json

  lifecycle {
    ignore_changes = [name]
  }
}

# Role
data "aws_iam_policy_document" "aws_alb_controller_assume" {
  count = 1
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_oidc_issuer_url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:facets-aws-alb-ingress-controller",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "aws_alb_controller" {
  count              = 1
  name               = "${substr(var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.cluster_name, 0, 64 - 11 - 17)}-ingress-iam-role"
  assume_role_policy = data.aws_iam_policy_document.aws_alb_controller_assume[0].json

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_role_policy_attachment" "aws_alb_controller" {
  count      = 1
  role       = aws_iam_role.aws_alb_controller[0].name
  policy_arn = aws_iam_policy.aws_alb_controller[0].arn
}

resource "helm_release" "aws_alb_ingress_controller" {
  depends_on = [
    aws_iam_role_policy_attachment.aws_alb_controller
  ]
  name       = "facets-aws-alb-ingress-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = lookup(local.aws-load-balancer-controller, "version", "1.9.2")
  namespace  = lookup(local.aws-load-balancer-controller, "namespace", "kube-system")
  set {
    name  = "region"
    value = var.environment.region
  }
  set {
    name  = "vpcId"
    value = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  }
  # When a network has multiple clusters deployed, ELB deployment may fail. Disabling this feature flag prevents cluster tag checks on subnets.
  # https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/subnet_discovery/#subnet-filtering
  # https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/configurations/#feature-gates
  set {
    name  = "controllerConfig.featureGates.SubnetsClusterTagCheck"
    value = false
  }
  values = [
    <<EOF
prometheus_id: ${try(var.inputs.prometheus_details.attributes.helm_release_id, "")}
EOF
    , yamlencode(local.constructed_helm_values),
    yamlencode(local.user_defined_helm_values)
  ]
}
