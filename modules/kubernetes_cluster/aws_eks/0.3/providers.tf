provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = try(kubernetes_secret_v1.facets-admin-token.data["ca.crt"], "na")
  token                  = try(kubernetes_secret_v1.facets-admin-token.data["token"], "na")
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = try(kubernetes_secret_v1.facets-admin-token.data["ca.crt"], "na")
    token                  = try(kubernetes_secret_v1.facets-admin-token.data["token"], "na")
  }
}