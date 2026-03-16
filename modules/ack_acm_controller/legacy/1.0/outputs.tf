locals {
  output_attributes = {
    namespace       = local.controller_namespace
    release_name    = helm_release.ack_acm.name
    chart_version   = var.instance.spec.chart_version
    role_arn        = module.irsa.iam_role_arn
    helm_release_id = helm_release.ack_acm.id
  }

  output_interfaces = {}
}
