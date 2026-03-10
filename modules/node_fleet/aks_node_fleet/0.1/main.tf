module "aks-node-fleet" {
  source   = "./aks/0.1"
  for_each = local.node_pools
  instance = {
    metadata = {
      name = each.key
      tags = lookup(lookup(each.value, "metadata", {}), "tags", {})
    }
    spec = {
      max_node_count = lookup(each.value, "max_node_count", null)
      min_node_count = lookup(each.value, "min_node_count", null)
      node_labels    = lookup(each.value, "node_labels", null)
      instance_type  = lookup(each.value, "instance_type", null)
      disk_size      = lookup(each.value, "disk_size", "G")
      # max_pods       = lookup(each.value, "max_pods", null)
      taints = local.processed_taints
      labels = merge(local.labels, {
        "facets-cloud-fleet-${var.instance_name}" = each.key
      })
    }
    advanced = {
      aks = {
        node_pool = merge({
          priority              = lookup(each.value, "type", null) == "spot" ? "Spot" : "Regular"
          enable_auto_scaling   = true
          vnet_subnet_id        = lookup(each.value, "vnet_subnet_id", null)
          enable_node_public_ip = lookup(each.value, "enable_node_public_ip", false)
          max_pods              = lookup(each.value, "max_pods", null)
          os_disk_type          = lookup(each.value, "os_disk_type", "Managed")
          os_type               = lookup(each.value, "os_type", "Linux")
          enable_auto_scaling   = lookup(each.value, "enable_auto_scaling", true)
          },
        lookup(local.aks_advanced, each.key, {}))
      }
    }
  }
  instance_name = each.key
  environment   = var.environment
  inputs        = var.inputs
}