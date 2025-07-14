locals {
  output_attributes = {}
  output_interfaces = {}
}

############## testing #####################
output "aks_node_pool_details" {
  description = "This will give you all the required outputs of aks module"
  # sensitive   = true
  value = {
    node_details = {
      cluster_id = azurerm_kubernetes_cluster_node_pool.node_pool.id
      name       = azurerm_kubernetes_cluster_node_pool.node_pool.name
      node_count = azurerm_kubernetes_cluster_node_pool.node_pool.node_count
      #      zones       = azurerm_kubernetes_cluster_node_pool.node_pool.zones
      taints      = azurerm_kubernetes_cluster_node_pool.node_pool.node_taints
      node_labels = azurerm_kubernetes_cluster_node_pool.node_pool.node_labels
      disk_size   = azurerm_kubernetes_cluster_node_pool.node_pool.os_disk_size_gb
    }
  }
}
############## Nodepool output based on schema #####################
output "name" {
  value = azurerm_kubernetes_cluster_node_pool.node_pool.name
}
output "taints" {
  value = azurerm_kubernetes_cluster_node_pool.node_pool.node_taints
}
output "labels" {
  value = azurerm_kubernetes_cluster_node_pool.node_pool.node_labels
}
