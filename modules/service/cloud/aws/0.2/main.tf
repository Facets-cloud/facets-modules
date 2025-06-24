locals {
  aws_advanced_config   = lookup(lookup(var.instance, "advanced", {}), "aws", {})
  aws_cloud_permissions = lookup(lookup(local.spec, "cloud_permissions", {}), "aws", {})
  enable_irsa           = lookup(local.aws_cloud_permissions, "enable_irsa", lookup(local.aws_advanced_config, "enable_irsa", false))
  iam_arns              = lookup(local.aws_cloud_permissions, "iam_policies", lookup(local.aws_advanced_config, "iam", {}))
  sa_name               = lower(var.instance_name)
  release_metadata_labels = {
    "facets.cloud/blueprint_version" = tostring(lookup(local.release_metadata.metadata, "blueprint_version", "NA")) == null ? "NA" : tostring(lookup(local.release_metadata.metadata, "blueprint_version", "NA"))
    "facets.cloud/override_version"  = tostring(lookup(local.release_metadata.metadata, "override_version", "NA")) == null ? "NA" : tostring(lookup(local.release_metadata.metadata, "override_version", "NA"))
  }
  namespace = lookup(var.instance.metadata, "namespace", null) == null ? var.environment.namespace : var.instance.metadata.namespace
  annotations = merge(
    local.enable_irsa ? { "eks.amazonaws.com/role-arn" = module.irsa.0.iam_role_arn } : { "iam.amazonaws.com/role" = aws_iam_role.application-role.0.arn },
    lookup(var.instance.metadata, "annotations", {})
  )
  labels        = merge(lookup(var.instance.metadata, "labels", {}), local.release_metadata_labels)
  name          = "${module.sr-name.name}-ar"
  resource_type = "service"
  resource_name = var.instance_name

  from_artifactories      = lookup(lookup(lookup(var.inputs, "artifactories", {}), "attributes", {}), "registry_secrets_list", [])
  from_kubernetes_cluster = lookup(lookup(lookup(lookup(var.inputs, "kubernetes_details", {}), "attributes", {}), "legacy_outputs", {}), "registry_secret_objects", [])

  # Transform taints from object format to string format for utility module compatibility
  kubernetes_node_pool_details = lookup(var.inputs, "kubernetes_node_pool_details", {})
  node_pool_taints            = lookup(local.kubernetes_node_pool_details, "taints", [])
  
  # Convert taints from {key: "key", value: "value", effect: "effect"} to "key=value:effect" format
  transformed_taints = [
    for taint_name, taint_config in local.node_pool_taints : 
    "${taint_config.key}=${taint_config.value}:${taint_config.effect}"
  ]

  # Create modified inputs with transformed taints
  modified_inputs = merge(var.inputs, {
    kubernetes_node_pool_details = merge(local.kubernetes_node_pool_details, {
      taints = local.transformed_taints
    })
  })
}

module "sr-name" {
  source          = "../../3_utility/name"
  is_k8s          = false
  globally_unique = true
  resource_name   = local.resource_name
  resource_type   = local.resource_type
  limit           = 60
  environment     = var.environment
}

module "irsa" {
  count                 = local.enable_irsa ? 1 : 0
  source                = "../../3_utility/aws_irsa"
  iam_arns              = local.iam_arns
  iam_role_name         = "${module.sr-name.name}-sr"
  namespace             = local.namespace
  sa_name               = "${local.sa_name}-sa"
  eks_oidc_provider_arn = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.oidc_provider_arn
}

module "app-helm-chart" {
  depends_on = [
    module.irsa, aws_iam_role.application-role,
    aws_iam_role_policy_attachment.policy-attach
  ]
  source                  = "../../3_utility/application"
  namespace               = local.namespace
  chart_name              = lower(var.instance_name)
  values                  = var.instance
  annotations             = local.annotations
  registry_secret_objects = length(local.from_artifactories) > 0 ? local.from_artifactories : local.from_kubernetes_cluster
  cc_metadata             = var.cc_metadata
  baseinfra               = var.baseinfra
  labels                  = local.labels
  cluster                 = var.cluster
  environment             = var.environment
  inputs                  = local.modified_inputs
  vpa_release_id          = lookup(lookup(lookup(var.inputs, "vpa_details", {}), "attributes", {}), "helm_release_id", "")
}

####### kube2iam policies ######
resource "aws_iam_role" "application-role" {
  count              = local.enable_irsa && length(local.iam_arns) > 0 ? 0 : 1
  name               = local.name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.node_group_iam_role_arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  for_each   = local.enable_irsa && length(local.iam_arns) > 0 ? {} : local.iam_arns
  role       = aws_iam_role.application-role.0.name
  policy_arn = lookup(each.value, "arn", null)
}
