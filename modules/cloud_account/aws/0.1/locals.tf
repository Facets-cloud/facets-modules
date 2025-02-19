locals {
  deploymentcontext = jsondecode(file("../deploymentcontext.json"))
  cluster           = lookup(local.deploymentcontext, "cluster", {})
}
