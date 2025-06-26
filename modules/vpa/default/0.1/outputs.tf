locals {
  output_attributes = {
    helm_release_id              = helm_release.vpa.id
    helm_release_name            = helm_release.vpa.name
    namespace                    = local.vpa_namespace
    version                      = local.vpa_version
    recommender_enabled          = local.recommender_enabled
    updater_enabled              = local.updater_enabled
    admission_controller_enabled = local.admission_controller_enabled
  }
  output_interfaces = {
  }
}