locals {
  name                      = module.name.name
  metadata                  = lookup(var.instance, "metadata", {})
  spec                      = lookup(var.instance, "spec", {})
  cluster                   = lookup(local.spec, "cluster", {})
  node_pools                = lookup(local.spec, "node_pools", {})
  default_node_pool         = lookup(local.node_pools, "default", {})
  dedicated_node_pool       = lookup(local.node_pools, "dedicated", {})
  default_reclaim_policy    = lookup(local.cluster, "default_reclaim_policy", "Delete")
  namespace                 = lookup(local.metadata, "namespace", "default")
  user_supplied_helm_values = lookup(local.secret_copier, "values", {})
  secret_copier             = lookup(local.spec, "secret-copier", {})

  facets_default_node_pool = {
    name            = "default-node-pool"
    node_class_name = "default"
    labels = {
      "managed-by"     = "facets"
      facets-node-type = "facets-default"
    }
  }

  facets_dedicated_node_pool = {
    name            = "dedicated-node-pool"
    node_class_name = "default"
    labels = {
      managed-by       = "facets"
      facets-node-type = "facets-dedicated"
    }
  }

  cloud_tags = {
    facetscontrolplane = split(".", var.cc_metadata.cc_host)[0]
    cluster            = var.cluster.name
    facetsclustername  = var.cluster.name
    facetsclusterid    = var.cluster.id
  }

  # Storage class data for AKS
  storage_class_data = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "aks-default-sc"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner = "disk.csi.azure.com"
    parameters = {
      storageaccounttype = "Premium_LRS"
      kind               = "Managed"
      cachingmode        = "ReadOnly"
    }
    allowVolumeExpansion = true
    reclaimPolicy        = local.default_reclaim_policy
    volumeBindingMode    = "Immediate"
  }

  default_node_pool_data = {
    apiVersion = "v1"
    kind       = "Node"
    metadata = {
      name   = local.facets_default_node_pool.name
      labels = local.facets_default_node_pool.labels
    }
    spec = {
      # AKS node configuration would be handled by the cluster itself
      # This is more for reference and labeling
    }
  }

  dedicated_node_pool_data = {
    apiVersion = "v1"
    kind       = "Node"
    metadata = {
      name   = local.facets_dedicated_node_pool.name
      labels = local.facets_dedicated_node_pool.labels
    }
    spec = {
      taints = [
        {
          key    = "facets.cloud/dedicated"
          value  = "true"
          effect = "NoSchedule"
        }
      ]
    }
  }
}