output "k8s_details" {
  value = {
    auth = {
      host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
      client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
      client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
      cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
      token                  = try(kubernetes_secret_v1.capillary-cloud-admin-token.data["token"], "na")
    }
    az_storage_account     = azurerm_storage_account.storageacct.name
    az_storage_account_id  = azurerm_storage_account.storageacct.id
    az_storage_account_key = azurerm_storage_account.storageacct.primary_access_key

    #registry_secrets        = local.secret_list
    #registry_secret_objects = [for i in local.secret_list : { name : i }]
    node_group_iam_role_arn = "na"
    cluster_id              = var.cluster.name

    #    stub_prometheus_dep = helm_release.prometheus-operator
    #stub_ecr_token_refresh = null_resource.wait-for-ecr-token-patch
    principalId    = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
    priority-class = kubernetes_priority_class.facets-critical.metadata[0].name
  }
}
output "registry_secret_objects" {
  value = []
}

output "legacy_outputs" {
  description = "Legacy outputs for backward compatibility" 
  value = {
    cluster_name         = azurerm_kubernetes_cluster.k8s.name
    cluster_endpoint     = azurerm_kubernetes_cluster.k8s.kube_config.0.host
    cluster_ca_certificate = azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate
    node_resource_group  = azurerm_kubernetes_cluster.k8s.node_resource_group
  }
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks_cluster.id
}

output "cluster_auto_upgrade" {
  value = {
    max_surge = local.max_surge
  } // "" for spot nodes
}
