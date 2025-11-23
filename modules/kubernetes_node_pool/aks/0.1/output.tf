locals {
  output_attributes = {
    node_pool_name = azurerm_kubernetes_cluster_node_pool.node_pool.name
    taints         = [for taint in var.instance.spec.taints : {
      key      = value.key
      value    = value.value
      operator = "Equal"
      effect   = value.effect
    }]
    node_selector  = azurerm_kubernetes_cluster_node_pool.node_pool.node_labels
    disk_size      = azurerm_kubernetes_cluster_node_pool.node_pool.os_disk_size_gb
    node_count     = azurerm_kubernetes_cluster_node_pool.node_pool.node_count
    cluster_id     = azurerm_kubernetes_cluster_node_pool.node_pool.id
  }
  output_interfaces = {}
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
