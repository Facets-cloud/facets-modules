#######################################################################
# Terraform Module Structure                                          #
#                                                                     #
# ── Guidance for Code Generators / AI Tools ───────────────────────── #
#                                                                     #
# • Keep this main.tf file **intentionally empty**.                   #
#   It serves only as the module's entry point.                       #
#                                                                     #
# • Create additional *.tf files that are **logically grouped**        #
#   according to the functionality and resources of the module.       #
#                                                                     #
# • Group related resources, data sources, locals, variables, and     #
#   outputs into separate files to improve clarity and maintainability.#
#                                                                     #
# • Choose file names that clearly reflect the purpose of the contents.#
#                                                                     #
# • Add new files as needed when new functionality areas are introduced,#
#   instead of expanding existing files indefinitely.                 #
#                                                                     #
# This ensures modules stay clean, scalable, and easy to navigate.    #
#######################################################################

# Kubernetes Deployment Resource
resource "kubernetes_deployment_v1" "this" {
  metadata {
    name        = var.instance.spec.metadata.name
    namespace   = var.instance.spec.metadata.namespace
    labels      = merge(var.instance.spec.metadata.labels, var.environment.cloud_tags)
    annotations = try(var.instance.spec.metadata.annotations, {})
  }

  spec {
    replicas = var.instance.spec.spec.replicas

    selector {
      match_labels = var.instance.spec.spec.selector.match_labels
    }

    template {
      metadata {
        labels      = merge(var.instance.spec.spec.template.metadata.labels, var.environment.cloud_tags)
        annotations = try(var.instance.spec.spec.template.metadata.annotations, {})
      }

      spec {
        dynamic "container" {
          for_each = var.instance.spec.spec.template.spec.containers
          content {
            name  = container.value.name
            image = container.value.image

            dynamic "port" {
              for_each = try(container.value.ports, [])
              content {
                container_port = port.value.container_port
                name           = port.value.name
                protocol       = port.value.protocol
              }
            }

            dynamic "env" {
              for_each = try(container.value.env, [])
              content {
                name  = env.value.name
                value = env.value.value
              }
            }

            resources {
              requests = try({
                cpu    = container.value.resources.requests.cpu
                memory = container.value.resources.requests.memory
              }, {})
              limits = try({
                cpu    = container.value.resources.limits.cpu
                memory = container.value.resources.limits.memory
              }, {})
            }
          }
        }

        restart_policy = var.instance.spec.spec.template.spec.restart_policy
      }
    }

    strategy {
      type = var.instance.spec.strategy.type

      dynamic "rolling_update" {
        for_each = var.instance.spec.strategy.type == "RollingUpdate" ? [1] : []
        content {
          max_surge       = try(var.instance.spec.strategy.rolling_update.max_surge, "25%")
          max_unavailable = try(var.instance.spec.strategy.rolling_update.max_unavailable, "25%")
        }
      }
    }
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "5m"
  }
}
