locals {
  spec               = lookup(var.instance, "spec", {})
  advanced           = lookup(var.instance, "advanced", {})
  tags               = lookup(local.advanced, "tags", {})
  node_type          = lookup(lookup(local.spec, "size", {}), "instance", lookup(lookup(local.advanced, "size", {}), "instance", "dax.r4.large"))
  aws_security_group = lookup(local.advanced, "aws_security_group", {})
  vpcCIDR            = lookup(lookup(local.aws_security_group, "ingress", {}), "cidr_blocks", null) == null ? [var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_cidr] : concat([var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_cidr], lookup(lookup(local.aws_security_group, "ingress"), "cidr_blocks", null))
  cidr_blocks        = lookup(local.advanced, "additional_cidr_blocks", [])
}