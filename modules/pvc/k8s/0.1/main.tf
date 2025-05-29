locals {
  spec              = lookup(var.instance, "spec", {})
  advanced          = lookup(var.instance, "advanced", {})
  additional_labels = lookup(local.advanced, "additional_labels", {})
  access_modes      = lookup(local.advanced, "access_modes", ["ReadWriteOnce"])
  storage_class     = lookup(local.advanced, "storage_class_name", null)
  volume_size       = lookup(lookup(local.spec, "size", {}), "volume", "5Gi")
  provisioned_for   = lookup(local.advanced, "provisioned_for", "pvc")
  namespace         = lookup(local.advanced, "namespace", var.environment.namespace)
  metadata          = lookup(var.instance, "metadata", {})
  annotations       = lookup(local.metadata, "annotations", {})
  name              = lookup(local.advanced, "name", "${module.name.name}-pvc")
}

module "pvc" {
  source             = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name               = local.name
  namespace          = local.namespace
  access_modes       = local.access_modes
  volume_size        = local.volume_size
  provisioned_for    = local.provisioned_for
  instance_name      = module.name.name
  kind               = "pvc"
  additional_labels  = local.additional_labels
  annotations        = local.annotations
  cloud_tags         = var.environment.cloud_tags
  storage_class_name = local.storage_class
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = true
  globally_unique = true
  resource_type   = "pvc"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 20
}