locals {
  output_interfaces = {}
  output_attributes = {
    "k8s_service_account_name"      = local.output_k8s_name
    "k8s_service_account_namespace" = local.output_k8s_namespace
    "gcp_service_account_email"     = local.gcp_sa_email
    "gcp_service_account_fqn"       = local.gcp_sa_fqn
    "gcp_service_account_name"      = local.k8s_sa_gcp_derived_name
    "gcp_service_account"           = local.use_existing_gcp_sa ? data.google_service_account.cluster_service_account[0] : google_service_account.cluster_service_account[0]
  }
}

output "k8s_service_account_name" {
  description = "Name of k8s service account."
  value       = local.output_k8s_name
}

output "k8s_service_account_namespace" {
  description = "Namespace of k8s service account."
  value       = local.output_k8s_namespace
}

output "gcp_service_account_email" {
  description = "Email address of GCP service account."
  value       = local.gcp_sa_email
}

output "gcp_service_account_fqn" {
  description = "FQN of GCP service account."
  value       = local.gcp_sa_fqn
}

output "gcp_service_account_name" {
  description = "Name of GCP service account."
  value       = local.k8s_sa_gcp_derived_name
}

output "gcp_service_account" {
  description = "GCP service account."
  value       = local.use_existing_gcp_sa ? data.google_service_account.cluster_service_account[0] : google_service_account.cluster_service_account[0]
}
