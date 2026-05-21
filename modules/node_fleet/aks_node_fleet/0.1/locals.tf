locals {
  spec         = lookup(var.instance, "spec", {})
  node_pools   = lookup(local.spec, "node_pools", {})
  cloud        = var.environment.cloud
  advanced     = lookup(var.instance, "advanced", {})
  aks_advanced = lookup(local.advanced, "aks", {})
  labels       = lookup(local.spec, "labels", {})
  taints       = lookup(local.spec, "taints", [])

  processed_taints = {
    for idx, taint in local.taints : idx => {
      key    = taint.key
      value  = taint.value
      effect = taint.effect
    }
  }
}