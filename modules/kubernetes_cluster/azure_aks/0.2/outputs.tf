locals {
  output_attributes = {
    oidc_issuer_url             = module.k8scluster.oidc_issuer_url
    cluster_id                  = module.k8scluster.aks_id
    cluster_name                = module.k8scluster.aks_name
    cluster_fqdn                = module.k8scluster.cluster_fqdn
    cluster_private_fqdn        = module.k8scluster.cluster_private_fqdn
    cluster_endpoint            = module.k8scluster.host
    cluster_location            = module.k8scluster.location
    cluster_sku_tier            = var.instance.spec.cluster.sku_tier
    cluster_kubernetes_version  = var.instance.spec.cluster.kubernetes_version
    node_resource_group         = module.k8scluster.node_resource_group
    resource_group_name         = var.inputs.network_details.attributes.resource_group_name
    auth_host                   = module.k8scluster.host
    auth_cluster_ca_certificate = base64decode(module.k8scluster.cluster_ca_certificate)
    client_certificate          = base64decode(module.k8scluster.client_certificate)
    client_key                  = base64decode(module.k8scluster.client_key)
  }
  output_interfaces = {
    kubernetes = {
      host                   = module.k8scluster.host
      client_key             = base64decode(module.k8scluster.client_key)
      client_certificate     = base64decode(module.k8scluster.client_certificate)
      cluster_ca_certificate = base64decode(module.k8scluster.cluster_ca_certificate)
    }
  }
}