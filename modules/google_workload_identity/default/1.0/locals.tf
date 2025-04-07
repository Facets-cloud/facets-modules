locals {
  # GCP service account ids must be <= 30 chars matching regex ^[a-z](?:[-a-z0-9]{4,28}[a-z0-9])$
  # KSAs do not have this naming restriction.
  spec                            = var.instance.spec
  name                            = lookup(var.instance.spec, "name", null)
  gcp_sa_name                     = lookup(var.instance.spec, "gcp_sa_name", null)
  k8s_sa_name                     = lookup(var.instance.spec, "k8s_sa_name", null)
  use_existing_gcp_sa             = lookup(var.instance.spec, "use_existing_gcp_sa", false)
  use_existing_k8s_sa             = lookup(var.instance.spec, "use_existing_k8s_sa", false)
  namespace                       = lookup(var.instance.spec, "namespace", var.environment.namespace)
  project_id                      = var.inputs.kubernetes_details.attributes.legacy_outputs.gcp_cloud.project_id
  gcp_sa_description              = lookup(var.instance.spec, "gcp_sa_description", "GCP Service Account bound to K8S Service Account ${local.project_id} ${local.k8s_given_name}")
  automount_service_account_token = lookup(var.instance.spec, "automount_service_account_token", false)
  annotate_k8s_sa                 = lookup(var.instance.spec, "annotate_k8s_sa", true)
  roles_map                       = lookup(var.instance.spec, "roles", {})
  roles                           = toset([for key, value in local.roles_map : lookup(value, "role", null)])

  gcp_given_name          = local.gcp_sa_name != null ? local.gcp_sa_name : trimsuffix(substr(local.name, 0, 30), "-")
  gcp_sa_email            = local.use_existing_gcp_sa ? data.google_service_account.cluster_service_account[0].email : google_service_account.cluster_service_account[0].email
  gcp_sa_fqn              = "serviceAccount:${local.gcp_sa_email}"
  k8s_given_name          = local.k8s_sa_name != null ? local.k8s_sa_name : local.name
  output_k8s_name         = local.use_existing_k8s_sa ? local.k8s_given_name : kubernetes_service_account.main[0].metadata[0].name
  output_k8s_namespace    = local.use_existing_k8s_sa ? local.namespace : kubernetes_service_account.main[0].metadata[0].namespace
  k8s_sa_gcp_derived_name = "serviceAccount:${local.project_id}.svc.id.goog[${local.namespace}/${local.output_k8s_name}]"
}
