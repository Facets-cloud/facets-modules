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


  metadata        = lookup(var.instance, "metadata", {})
  tags            = merge(var.environment.cloud_tags, lookup(local.metadata, "tags", {}))
  spec            = lookup(var.instance, "spec", {})
  runtime         = lookup(local.spec, "runtime", {})
  release         = lookup(local.spec, "release", {})
  advanced        = lookup(var.instance, "advanced", {})
  advanced_common = lookup(local.advanced, "common", {})
  deployment_id = lookup(local.advanced_common, "pass_deployment_id", false) ? var.environment.deployment_id : ""
  env_vars = merge(lookup(local.dep_cluster, "globalVariables", {}),
    lookup(local.advanced_common, "include_common_env_variables", false) ? var.environment.common_environment_variables : {}, lookup(local.spec, "env", {}),
    length(local.deployment_id) > 0 ? {
      deployment_id = local.deployment_id
    } : {}
  )
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 255
  resource_name   = var.instance_name
  resource_type   = "ervice"
  globally_unique = false
  is_k8s          = false
  prefix          = "s"
}



resource "helm_release" "knative" {
  name            = module.name.name
  chart           = "https://kiwigrid.github.io"
  repository      = "kiwigrid/any-resource"
  namespace       = var.environment.namespace
  version         = "0.1.0"
  cleanup_on_fail = true
  timeout         = 720
  atomic          = false

  values = [
    yamlencode(local.knative_service_helm_values)
  ]
}

#module "knative_service" {
#  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
#  namespace       = var.environment.namespace
#  advanced_config = {}
#  name            = module.name.name
#  resources_data  = [
#    yamlencode(local.knative_service_helm_values)
#  ]
#}
