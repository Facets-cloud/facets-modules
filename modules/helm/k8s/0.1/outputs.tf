locals {
  output_attributes = {
    release_name = helm_release.external_helm_charts.name
  }
  output_interfaces = {}
}

output "metadata" {
  value = helm_release.external_helm_charts.metadata
}
output "status" {
  value = helm_release.external_helm_charts.status
}
