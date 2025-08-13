
locals {
  deploy_context               = jsondecode(file("../deploymentcontext.json"))
  dep_cluster                  = lookup(local.deploy_context, "cluster", {})
  all_artifactories            = lookup(local.deploy_context, "artifacts", {})
  all_artifacts                = merge(values(local.all_artifactories)...)
  artifactory                  = lookup(lookup(var.values.spec.release, "build", {}), "artifactory", "NOT_FOUND")
  artifact_name                = lookup(lookup(var.values.spec.release, "build", {}), "name", "NOT_FOUND")
  _artifact_name               = lookup(var.values, "_artifact_name", "NOT_FOUND")
  artifactUri                  = lookup(lookup(lookup(local.all_artifactories, local.artifactory, {}), local.artifact_name, {}), "artifactUri", "NOT_FOUND")
  build_id_lookup              = lookup(lookup(lookup(local.all_artifactories, local.artifactory, {}), local.artifact_name, {}), "buildId", lookup(lookup(local.all_artifacts, local._artifact_name, {}), "buildId", "NOT_FOUND"))
  image_lookup                 = lookup(var.values.spec.release, "image", "NOT_FOUND")
  advanced_config_values       = lookup(local.advanced_config, "values", {})
  kubernetes_node_pool_details = lookup(var.inputs, "kubernetes_node_pool_details", {})
  image_id                     = local.artifactUri == "NOT_FOUND" ? local.image_lookup : local.artifactUri
  build_id                     = local.build_id_lookup == "NOT_FOUND" ? (local.image_lookup != "NOT_FOUND" ? "NA" : "NOT_FOUND") : local.build_id_lookup
  common_advanced              = lookup(lookup(var.values, "advanced", {}), "common", {})
  all_secrets                  = lookup(local.common_advanced, "include_common_env_secrets", false) ? var.environment.secrets : {}
  advanced_config              = lookup(local.common_advanced, "app_chart", {})
  env_vars = merge(
    lookup(local.common_advanced, "include_common_env_variables", false) ? var.environment.common_environment_variables : {},
    true ? lookup(var.values.spec, "env", {}) : {}
  )
  deployment_id                = lookup(local.common_advanced, "pass_deployment_id", false) ? var.environment.deployment_id : ""
  taints                       = lookup(local.kubernetes_node_pool_details, "taints", [])
  chart_name                   = lookup(lookup(lookup(var.values, "metadata", {}), "labels", {}), "resourceName", var.chart_name)
  parsed_taints = [
    for taint in local.taints : {
      key      = split("=", taint)[0]
      value    = split("=", split(":", taint)[0])[1]
      effect   = split(":", taint)[1]
      operator = "Equal"
    }
  ]
  tolerations = lookup(local.advanced_config_values, "tolerations", {})
  node_selector = merge(
    lookup(local.advanced_config_values, "node_selector", {}),
    lookup(local.kubernetes_node_pool_details, "node_selector", {})
  )
  build_id_env = lookup(local.advanced_config_values, "include_build_id_env", false) ? { BUILD_ID = local.build_id } : {}
  adv_tolerations = [
    for toleration_key, toleration in local.tolerations :
    {
      key      = toleration.key
      operator = toleration.operator
      effect   = toleration.effect
      value    = toleration.value
    }
  ]
  all_tolerations = concat(local.adv_tolerations, local.parsed_taints, var.environment.default_tolerations)

  size = lookup(lookup(var.values.spec, "runtime", {}), "size", {
    cpu          = "1000m"
    cpu_limit    = "1000m"
    memory       = "1000Mi"
    memory_limit = "1000Mi"
  })

  cpu          = lookup(local.size, "cpu", "1000m")
  cpu_limit    = lookup(local.size, "cpu_limit", local.cpu)
  memory       = lookup(local.size, "memory", "1000Mi")
  memory_limit = lookup(local.size, "memory_limit", local.memory)

  # We need to split cpu/memory limit as it may contain unit
  split_cpu_limit          = regex("([0-9.]+)([a-zA-Z]+)?", local.cpu_limit)
  processed_cpu_request    = "${local.split_cpu_limit[0] * var.cluster.k8sRequestsToLimitsRatio}${local.split_cpu_limit[1] != null ? local.split_cpu_limit[1] : ""}"
  split_memory_limit       = regex("([0-9.]+)([a-zA-Z]+)?", local.memory_limit)
  processed_memory_request = "${local.split_memory_limit[0] * var.cluster.k8sRequestsToLimitsRatio}${local.split_memory_limit[1] != null ? local.split_memory_limit[1] : ""}"

  processed_size = {
    cpu_limit    = lookup(local.size, "cpu_limit", local.cpu_limit)
    cpu          = lookup(local.size, "cpu", local.processed_cpu_request)
    memory_limit = lookup(local.size, "memory_limit", local.memory_limit)
    memory       = lookup(local.size, "memory", local.processed_memory_request)
  }

  type           = lookup(var.values.spec, "type", "application")
  pvcs           = lookup(var.values.spec, "persistent_volume_claims", {})
  instance_count = lookup(lookup(var.values.spec, "runtime", {}), "instance_count", 1)
  sts_pvcs = local.type == "statefulset" ? merge(slice(flatten([
    for idx in range(local.instance_count) : {
      for pvc_name, pvc_spec in local.pvcs : "${pvc_name}-vol-${var.chart_name}-${idx}" => merge(pvc_spec, { index = idx })
  }]), 0, local.instance_count)...) : {}

  pod_distribution_enabled = lookup(local.advanced_config_values, "pod_distribution_enabled", true)
  pod_distribution = local.pod_distribution_enabled ? length(local.kubernetes_node_pool_details) > 0 ? {
    "facets-pod-topology-spread" = {
      max_skew           = 1
      when_unsatisfiable = "DoNotSchedule"
      topology_key       = lookup(lookup(local.kubernetes_node_pool_details, "attributes", {}), "topology_spread_key", "")
    }
  } : lookup(local.advanced_config_values, "pod_distribution", {}) : null
  sidecars        = lookup(var.values.spec, "sidecars", lookup(local.advanced_config_values, "sidecars", {}))
  init_containers = lookup(var.values.spec, "init_containers", lookup(local.advanced_config_values, "init_containers", {}))
}

resource "helm_release" "app-chart" {
  depends_on = [module.sts-pvc]

  name             = "${var.chart_name}-app-chart"
  chart            = "${path.module}/app-chart"
  namespace        = var.namespace
  version          = "0.3.0"
  create_namespace = var.namespace == "default" ? false : true
  timeout          = lookup(local.advanced_config, "timeout", 300)
  wait             = lookup(local.advanced_config, "wait", false)
  atomic           = lookup(local.advanced_config, "atomic", false)
  max_history      = 10
  cleanup_on_fail  = lookup(local.advanced_config, "cleanup_on_fail", true)
  values = [
    yamlencode(var.values),
    yamlencode({
      metadata = {
        name        = var.chart_name
        annotations = merge(var.annotations, { buildId = local.build_id })
        labels = merge(
          var.labels,
          {
            artifact_external_id = can(regex("^(([a-za-z0-9][-a-za-z0-9_.]*)?[a-za-z0-9])?$", lower(local.build_id))) ? lower(local.build_id) : "INVALID"
            artifact_name        = can(regex("^(([a-za-z0-9][-a-za-z0-9_.]*)?[a-za-z0-9])?$", lower(local.artifact_name))) ? lower(local.artifact_name) : "INVALID"
          }
        )
      }
      spec = {
        release = {
          image = local.image_id
        }
        runtime = merge(
          lookup(var.values.spec, "runtime", {}),
          {
            size = local.processed_size
          }
        )
      }
    }),
    yamlencode({
      spec = {
        env = merge(lookup(local.dep_cluster, "globalVariables", {}), local.env_vars, local.build_id_env, local.all_secrets,
          length(local.deployment_id) > 0 ? {
            deployment_id = local.deployment_id
          } : {}
        )
      }
    }),
    yamlencode({
      advanced = {
        common = {
          app_chart = {
            values = {
              tolerations        = local.all_tolerations
              node_selector      = local.node_selector
              pod_distribution   = local.pod_distribution
              image_pull_secrets = var.registry_secret_objects
              init_containers    = local.init_containers
              sidecars           = local.sidecars
            }
          }
        }
      }
    })
  ]
}

module "sts-pvc" {
  for_each = local.sts_pvcs

  source          = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name            = each.key
  namespace       = var.namespace
  access_modes    = [each.value.access_mode]
  volume_size     = each.value.storage_size
  provisioned_for = "${var.chart_name}-app-chart-${each.value.index}"
  instance_name   = local.chart_name
  kind            = "service"
  additional_labels = merge({
    "app"                        = var.chart_name
    "app.kubernetes.io/name"     = var.chart_name
    "app.kubernetes.io/instance" = "${var.chart_name}-app-chart"
  }, var.labels)
  cloud_tags = var.environment.cloud_tags
}
