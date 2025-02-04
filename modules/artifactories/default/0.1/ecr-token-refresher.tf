resource "kubernetes_secret_v1" "ecr-token-refresher-configs" {
  for_each = local.artifactories_ecr
  metadata {
    name      = "ecr-tkn-renewer-${local.name}-${each.key}"
    namespace = local.namespace
  }
  data = {
    aws_access_key_id     = each.value["awsKey"]
    aws_access_secret_key = each.value["awsSecret"]
    aws_account           = each.value["awsAccountId"]
    aws_region            = each.value["awsRegion"]
    registry_url          = each.value["uri"]
    registry_name         = each.key
    secret_name           = "${local.name}-${each.key}"
  }
}

resource "kubernetes_cron_job_v1" "ecr-token-refresher-cron" {
  for_each = local.artifactories_ecr
  metadata {
    name      = "ecr-tkn-renewer-${local.name}-${each.key}"
    namespace = local.namespace
  }
  spec {
    concurrency_policy            = "Allow"
    failed_jobs_history_limit     = 1
    schedule                      = "5 */3 * * *"
    starting_deadline_seconds     = 20
    successful_jobs_history_limit = 1
    suspend                       = false
    job_template {
      metadata {}
      spec {
        backoff_limit = 4
        template {
          metadata {}
          spec {
            priority_class_name = "facets-critical"
            toleration {
              operator = "Exists"
            }
            service_account_name            = kubernetes_service_account.ecr-token-refresher-sa[each.key].metadata.0.name
            automount_service_account_token = true
            node_selector = {
              "kubernetes.io/arch" = "amd64"
            }
            container {
              name              = "kubectl"
              image             = "xynova/aws-kubectl"
              image_pull_policy = "Always"
              command           = ["/bin/sh", "-c", file("${path.module}/ecr-token-refresher-command")]
              env {
                name = "AWS_ACCOUNT"
                value_from {
                  secret_key_ref {
                    key  = "aws_account"
                    name = "ecr-tkn-renewer-${local.name}-${each.key}"
                  }
                }
              }
              env {
                name = "AWS_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    key  = "aws_access_key_id"
                    name = "ecr-tkn-renewer-${local.name}-${each.key}"
                  }
                }
              }
              env {
                name = "AWS_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    key  = "aws_access_secret_key"
                    name = "ecr-tkn-renewer-${local.name}-${each.key}"
                  }
                }
              }
              env {
                name = "AWS_REGION"
                value_from {
                  secret_key_ref {
                    key  = "aws_region"
                    name = "ecr-tkn-renewer-${local.name}-${each.key}"
                  }
                }
              }
              env {
                name = "KEY_NAME"
                value_from {
                  secret_key_ref {
                    key  = "secret_name"
                    name = "ecr-tkn-renewer-${local.name}-${each.key}"
                  }
                }
              }
              env {
                name = "DOCKER_REGISTRY_SERVER"
                value_from {
                  secret_key_ref {
                    key  = "registry_url"
                    name = "ecr-tkn-renewer-${local.name}-${each.key}"
                  }
                }
              }
              env {
                name  = "NAMESPACE"
                value = local.namespace
              }
              env {
                name  = "INSTANCE_LABELS"
                value = local.labels
              }
            }
            restart_policy = "Never"
          }
        }
      }
    }
  }
}

resource "kubernetes_role_v1" "ecr-token-refresher-role" {
  for_each = local.artifactories_ecr
  metadata {
    name      = "ecr-tkn-renewer-${local.name}-${each.key}"
    namespace = local.namespace
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "create", "delete", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get", "patch", "list"]
  }
}

resource "kubernetes_service_account" "ecr-token-refresher-sa" {
  for_each = local.artifactories_ecr
  metadata {
    name      = "ecr-tkn-renewer-${local.name}-${each.key}"
    namespace = local.namespace
  }
}

resource "kubernetes_role_binding_v1" "ecr-token-refresher-crb" {
  for_each = local.artifactories_ecr
  metadata {
    name      = "ecr-tkn-renewer-${local.name}-${each.key}"
    namespace = local.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.ecr-token-refresher-role[each.key].metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ecr-token-refresher-sa[each.key].metadata.0.name
    namespace = local.namespace
  }
}

resource "null_resource" "patch_default_sa" {
  triggers = {
    host         = local.host
    token        = local.token
    "registries" = jsonencode(local.artifactory_list)
  }
  depends_on = [null_resource.wait-for-ecr-token-patch]
  provisioner "local-exec" {
    command = "/bin/bash ../tfmain/scripts/run_with_kubeconfig.sh kubectl patch sa default -p '${jsonencode({ "imagePullSecrets" = local.registry_secrets_list })}'"
    environment = {
      SERVER = local.host
      CA     = local.cluster_ca_certificate
      TOKEN  = local.token
    }
  }
}

resource "null_resource" "patch_admin_sa" {
  count = var.cluster.cloud == "AWS" ? 1 : 0
  triggers = {
    host         = local.host
    token        = local.token
    "registries" = jsonencode(local.artifactory_list)
  }
  depends_on = [null_resource.wait-for-ecr-token-patch]
  provisioner "local-exec" {
    command = "/bin/bash ../tfmain/scripts/run_with_kubeconfig.sh kubectl patch sa capillary-cloud-admin -p '${jsonencode({ "imagePullSecrets" = local.registry_secrets_list })}'"
    environment = {
      SERVER = local.host
      CA     = local.cluster_ca_certificate
      TOKEN  = local.token
    }
  }
}

resource "null_resource" "wait-for-ecr-token-patch" {
  triggers = {
    host       = local.host
    token      = local.token
    registries = jsonencode(local.artifactory_list)
  }
  for_each   = local.artifactories_ecr
  depends_on = [kubernetes_cron_job_v1.ecr-token-refresher-cron]
  provisioner "local-exec" {
    command = "/bin/bash ../tfmain/scripts/trigger-ecr-token-refresh.sh"
    environment = {
      SERVER    = local.host
      CA        = local.cluster_ca_certificate
      TOKEN     = local.token
      CRON_NAME = kubernetes_cron_job_v1.ecr-token-refresher-cron[each.key].metadata[0].name
      NAMESPACE = local.namespace
    }
  }
}
