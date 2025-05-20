locals {
  deploymentcontext = jsondecode(file("../deploymentcontext.json"))
  cluster           = lookup(local.deploymentcontext, "cluster", {})
  cloud             = lookup(local.cluster, "cloud", null)
}
