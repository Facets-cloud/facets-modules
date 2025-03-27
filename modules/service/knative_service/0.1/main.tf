locals {
  deploy_context    = jsondecode(file("../deploymentcontext.json"))
  dep_cluster       = lookup(local.deploy_context, "cluster", {})
  all_artifactories = lookup(local.deploy_context, "artifacts", {})
  all_artifacts     = merge(values(local.all_artifactories)...)
  artifactory       = lookup(lookup(local.release, "build", {}), "artifactory", "NOT_FOUND")
  artifact_name     = lookup(lookup(local.release, "build", {}), "name", "NOT_FOUND")
  _artifact_name    = lookup(var.instance, "_artifact_name", "NOT_FOUND")
  artifactUri       = lookup(lookup(lookup(local.all_artifactories, local.artifactory, {}), local.artifact_name, {}), "artifactUri", "NOT_FOUND")
  build_id_lookup   = lookup(lookup(lookup(local.all_artifactories, local.artifactory, {}), local.artifact_name, {}), "buildId", lookup(lookup(local.all_artifacts, local._artifact_name, {}), "buildId", "NOT_FOUND"))
  image_lookup      = lookup(local.release, "image", "NOT_FOUND")
  image_id          = local.artifactUri == "NOT_FOUND" ? local.image_lookup : local.artifactUri
  build_id          = local.build_id_lookup == "NOT_FOUND" ? (local.image_lookup != "NOT_FOUND" ? "NA" : "NOT_FOUND") : local.build_id_lookup


  metadata = lookup(var.instance, "metadata", {})
  tags     = merge(var.environment.cloud_tags, lookup(local.metadata, "tags", {}))
  spec     = lookup(var.instance, "spec", {})
  runtime  = lookup(local.spec, "runtime", {})
  release  = lookup(local.spec, "release", {})

  advanced        = lookup(var.instance, "advanced", {})
  advanced_common = lookup(local.advanced, "common", {})
  deployment_id   = lookup(local.advanced_common, "pass_deployment_id", false) ? var.environment.deployment_id : ""
  env_vars = merge(lookup(local.dep_cluster, "globalVariables", {}),
    lookup(local.advanced_common, "include_common_env_variables", false) ? var.environment.common_environment_variables : {}, lookup(local.spec, "env", {}),
    length(local.deployment_id) > 0 ? {
      deployment_id = local.deployment_id
    } : {}
  )

  aws_cloud_permissions = lookup(lookup(local.spec, "cloud_permissions", {}), "aws", {})
  iam_arns              = lookup(local.aws_cloud_permissions, "iam_policies", {})
  enable_irsa           = length(local.iam_arns) > 0 ? true : false
  sa_name               = lower(var.instance_name)
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 253
  resource_name   = var.instance_name
  resource_type   = "service"
  globally_unique = false
  is_k8s          = true
}

module "sr-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = local.resource_labels.resourceName
  resource_type   = local.resource_labels.resourceType
  limit           = 60
  environment     = var.environment
}

module "irsa" {
  count                 = local.enable_irsa ? 1 : 0
  source                = "github.com/Facets-cloud/facets-utility-modules//aws_irsa"
  iam_arns              = local.iam_arns
  iam_role_name         = "${module.sr-name.name}-sr"
  namespace             = var.environment.namespace
  sa_name               = "${local.sa_name}-sa"
  eks_oidc_provider_arn = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.oidc_provider_arn
}



module "knative_service" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
  namespace       = var.environment.namespace
  advanced_config = {}
  name            = module.name.name
  resources_data = [
    local.knative_values,
    local.serviceAccount
  ]
}
