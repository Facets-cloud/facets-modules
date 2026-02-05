locals {
  name      = lower(var.environment.namespace == "default" ? var.instance_name : "${var.environment.namespace}-${var.instance_name}")
  namespace = var.environment.namespace
  version   = lookup(var.instance.spec, "version", "v1.4.1")
  channel   = lookup(var.instance.spec, "channel", "experimental")

  # Build the install URL based on version and channel
  install_file = local.channel == "experimental" ? "experimental-install.yaml" : "standard-install.yaml"
  install_url  = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${local.version}/${local.install_file}"

  # Tolerations: merge environment defaults with facets dedicated tolerations
  tolerations = concat(
    lookup(var.environment, "default_tolerations", []),
    try(var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations, [])
  )

  # Node selector from kubernetes_details legacy outputs
  node_selector = try(var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_node_selectors, {})
}

# ServiceAccount for Gateway API CRD installer Job
resource "kubernetes_service_account_v1" "gateway_api_crd_installer" {
  metadata {
    name      = "${local.name}-gateway-api-crd-installer"
    namespace = local.namespace
  }
}

# ClusterRole for Gateway API CRD installer
resource "kubernetes_cluster_role_v1" "gateway_api_crd_installer" {
  metadata {
    name = "${local.name}-gateway-api-crd-installer"
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "create", "update", "patch"]
  }
}

# ClusterRoleBinding for Gateway API CRD installer
resource "kubernetes_cluster_role_binding_v1" "gateway_api_crd_installer" {
  metadata {
    name = "${local.name}-gateway-api-crd-installer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.gateway_api_crd_installer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.gateway_api_crd_installer.metadata[0].name
    namespace = local.namespace
  }
}

# Job to install Gateway API CRDs
resource "kubernetes_job_v1" "gateway_api_crd_installer" {
  metadata {
    name      = "${local.name}-gateway-api-crd-installer"
    namespace = local.namespace
  }

  spec {
    template {
      metadata {
        labels = {
          app = "gateway-api-crd-installer"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.gateway_api_crd_installer.metadata[0].name
        restart_policy       = "OnFailure"

        # Node selector from kubernetes_details legacy outputs
        node_selector = local.node_selector

        # Dynamic tolerations from environment and kubernetes_details
        dynamic "toleration" {
          for_each = local.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = lookup(toleration.value, "value", null)
            effect   = toleration.value.effect
          }
        }

        container {
          name    = "kubectl"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/sh", "-c"]
          args = [
            # Using --server-side to avoid annotation size limit (262KB)
            "kubectl apply --server-side -f ${local.install_url}"
          ]
        }
      }
    }

    backoff_limit = 3
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [
    kubernetes_cluster_role_binding_v1.gateway_api_crd_installer
  ]
}
