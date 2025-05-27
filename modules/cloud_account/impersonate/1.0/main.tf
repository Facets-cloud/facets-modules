#######################################################################
# Terraform Module Structure                                          #
#                                                                     #
# ── Guidance for Code Generators / AI Tools ───────────────────────── #
#                                                                     #
# • Keep this main.tf file **intentionally empty**.                   #
#   It serves only as the module's entry point.                       #
#                                                                     #
# • Create additional *.tf files that are **logically grouped**        #
#   according to the functionality and resources of the module.       #
#                                                                     #
# • Group related resources, data sources, locals, variables, and     #
#   outputs into separate files to improve clarity and maintainability.#
#                                                                     #
# • Choose file names that clearly reflect the purpose of the contents.#
#                                                                     #
# • Add new files as needed when new functionality areas are introduced,#
#   instead of expanding existing files indefinitely.                 #
#                                                                     #
# This ensures modules stay clean, scalable, and easy to navigate.    #
#######################################################################

locals {
  spec            = lookup(var.instance, "spec", {})
  service_account = lookup(local.spec, "service_account", null)
  project         = lookup(local.spec, "project", null)
  region          = lookup(local.spec, "region", "us-central1")
}

data "google_service_account" "user_service_account" {
  provider = google.controlplane
  account_id = local.service_account
}

data "google_client_openid_userinfo" "me" {
  provider = google.controlplane
}

resource "google_service_account_iam_member" "cp-release-permissions" {
  provider           = google.controlplane
  service_account_id = data.google_service_account.user_service_account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${data.google_client_openid_userinfo.me.email}"
}
