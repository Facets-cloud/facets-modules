locals {
  output_interfaces = {}
  output_attributes = {
    "k8s_sa_name"      = local.output_k8s_name
    "k8s_sa_namespace" = local.output_k8s_namespace
    "gcp_sa_email"     = local.gcp_sa_email
    "gcp_sa_fqn"       = local.gcp_sa_fqn
    "gcp_sa_name"      = local.k8s_sa_gcp_derived_name
    "gcp_sa_id"        = local.gcp_sa_id
  }
}