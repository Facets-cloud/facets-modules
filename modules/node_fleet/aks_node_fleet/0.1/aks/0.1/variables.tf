#variable "cc_metadata" {
#  type = any
#  default = {
#    tenant_base_domain : "tenant.facets.cloud"
#  }
#}

variable "instance" {
  type = any
  default = {
    "flavor" = "aks",
    "spec" = {
      "instance_type"  = "",
      "min_node_count" = "",
      "max_node_count" = "",
      "disk_size"      = "",
      "zones"          = [],
      "taints"         = [],
      "node_labels"    = {}
    },
    "advanced" = {
      aks = {
        node_pool = {}
    } }
  }
}


variable "instance_name" {
  type    = string
  default = "mynodepool"
}
variable "environment" {
  type = any
  default = {
    namespace          = "testing",
    Cluster            = "azure-infra-dev",
    FacetsControlPlane = "facetsdemo.console.facets.cloud"
  }
}

variable "inputs" {
  type    = any
  default = {}
}