resource "kubernetes_service_account" "facets-admin" {
  depends_on = [ module.eks ]
  provider = kubernetes.k8s
  metadata {
    name = "facets-admin"
  }

  lifecycle {
    ignore_changes = ["image_pull_secret"]
  }
}

resource "kubernetes_cluster_role_binding" "facets-admin-crb" {
  provider = kubernetes.k8s
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
    name      = kubernetes_service_account.facets-admin.metadata[0].name
    namespace = "default"
  }
}
resource "kubernetes_secret_v1" "facets-admin-token" {
  provider = kubernetes.k8s
  depends_on = [kubernetes_service_account.facets-admin]
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = "facets-admin"
    }
    name = "${kubernetes_service_account.facets-admin.metadata[0].name}-secret"
  }
  type = "kubernetes.io/service-account-token"
}


resource "null_resource" "add-k8s-creds-backend" {
  depends_on = [kubernetes_secret_v1.facets-admin-token]
  triggers = {
    k8s_host = module.eks.cluster_endpoint
  }
  provisioner "local-exec" {
    command = <<EOF
curl -X POST "https://${var.cc_metadata.cc_host}/cc/v1/clusters/${var.cluster.id}/credentials" -H "accept: */*" -H "Content-Type: application/json" -d "{ \"kubernetesApiEndpoint\": \"${module.eks.cluster_endpoint}\", \"kubernetesToken\": \"${try(kubernetes_secret_v1.facets-admin-token.data["token"], "na")}\"}" -H "X-DEPLOYER-INTERNAL-AUTH-TOKEN: ${var.cc_metadata.cc_auth_token}"
EOF
  }
}

resource "kubernetes_priority_class" "facets-critical" {
  provider = kubernetes.k8s
  depends_on = [kubernetes_cluster_role_binding.facets-admin-crb]
  metadata {
    name = "facets-critical"
  }
  value = 1000000000
}