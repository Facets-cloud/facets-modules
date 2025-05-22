locals {
  deploymentcontext = jsondecode(file("../deploymentcontext.json"))
  cluster           = lookup(local.deploymentcontext, "cluster", {})
  cloud             = lower(lookup(local.cluster, "cloud", null))
}
