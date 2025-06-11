resource "helm_release" "alert_group_helm" {
  name            = "alert-group-${var.instance_name}"
  chart           = "./any-resource-0.1.0.tgz"
  repository      = "kiwigrid"
  namespace       = var.environment.namespace
  version         = "0.1.0"
  cleanup_on_fail = true
  timeout         = 720
  atomic          = false

  values = [
    <<EOF
prometheusId: ${var.inputs.prometheus_details.attributes.helm_release_id}
EOF
    , local.helm_values_yaml
  ]
}