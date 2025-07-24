locals {
  output_attributes = {
    release_name      = helm_release.tekton.name
    release_namespace = helm_release.tekton.namespace
    resource_name     = module.name.name
    resource_type     = "tekton"
  }

  output_interfaces = {}
}