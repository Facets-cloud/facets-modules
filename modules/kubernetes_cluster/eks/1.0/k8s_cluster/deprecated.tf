# Deprecated Kubernetes resources - moved out for exec plugin implementation
# These resources should be managed externally

resource "kubernetes_service_account" "facets-admin" {
  count      = 0  # Disabled - using exec plugin instead
  provider   = kubernetes.k8s
  depends_on = [module.eks]
  metadata {
    name = "facets-admin"
  }
  lifecycle {
    ignore_changes = ["image_pull_secret"]
  }
}

resource "kubernetes_cluster_role_binding" "facets-admin-crb" {
  count      = 0  # Disabled - using exec plugin instead
  provider   = kubernetes.k8s
  depends_on = [kubernetes_service_account.facets-admin]
  metadata {
    name = "facets-admin-crb"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "facets-admin"
    namespace = "default"
  }
}

resource "kubernetes_secret_v1" "facets-admin-token" {
  count      = 0  # Disabled - using exec plugin instead
  provider   = kubernetes.k8s
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = "facets-admin"
    }
    name = "facets-admin-secret"
  }
  type = "kubernetes.io/service-account-token"
}

resource "null_resource" "add-k8s-creds-backend" {
  count      = 0  # Disabled - no longer needed with exec plugin
  depends_on = [module.eks]
  triggers = {
    k8s_host = module.eks.cluster_endpoint
  }
  provisioner "local-exec" {
    command = "echo 'Credential upload disabled - using exec plugin'"
  }
}

resource "kubernetes_priority_class" "facets-critical" {
  count      = 0  # Disabled - manage via GitOps instead
  provider   = kubernetes.k8s
  depends_on = [module.eks]
  metadata {
    name = "facets-critical"
  }
  value = 1000000000
}