resource "kubernetes_service_account" "facets-admin" {
  depends_on = [
    module.eks, data.aws_eks_cluster.cluster, data.aws_eks_cluster_auth.cluster
  ]
  metadata {
    name = "facets-admin"
  }

  lifecycle {
    ignore_changes = ["image_pull_secret"]
  }
}

resource "kubernetes_cluster_role_binding" "facets-admin-crb" {
  depends_on = [
    module.eks, data.aws_eks_cluster.cluster, data.aws_eks_cluster_auth.cluster
  ]
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
    name      = kubernetes_service_account.facets-admin.metadata[0].name
    namespace = "default"
  }
}
resource "kubernetes_secret_v1" "facets-admin-token" {
  depends_on = [
    module.eks, data.aws_eks_cluster.cluster, data.aws_eks_cluster_auth.cluster
  ]
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = "facets-admin"
    }
    name = "${kubernetes_service_account.facets-admin.metadata[0].name}-secret"
  }
  type = "kubernetes.io/service-account-token"
}
