locals {
  spec                = lookup(var.instance, "spec", {})
  advanced            = lookup(var.instance, "advanced", {})
  aws_efs_file_system = lookup(local.advanced, "aws_efs", {})
  vpc_details         = var.inputs.network_details.attributes.legacy_outputs.vpc_details
  metadata_name       = lookup(lookup(var.instance, "metadata", {}), "name", "")
  instance_name       = length(local.metadata_name) > 0 ? local.metadata_name : var.instance_name
}