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
    auth_token                  = data.azurerm_client_config.current.access_token
    auth_cluster_ca_certificate = base64decode(module.k8scluster.cluster_ca_certificate)
    vpc_id                      = var.inputs.network_details.attributes.vpc_id
    subnet_ids                  = var.inputs.network_details.attributes.private_subnet_ids
    network_profile             = module.k8scluster.network_profile
    identity_type               = module.k8scluster.cluster_identity.type
    identity_tenant_id          = module.k8scluster.cluster_identity.tenant_id
    identity_principal_id       = module.k8scluster.cluster_identity.principal_id
    log_analytics_workspace_id  = module.k8scluster.azurerm_log_analytics_workspace_id
  }
  output_interfaces = {
    kubernetes_config = {
      host                   = module.k8scluster.host
      client_key             = base64decode(module.k8scluster.client_key)
      config_path            = "null"
      config_context         = module.k8scluster.aks_name
      client_certificate     = base64decode(module.k8scluster.client_certificate)
      cluster_ca_certificate = base64decode(module.k8scluster.cluster_ca_certificate)
    }
  }
}