locals {
  output_interfaces = {}
  output_attributes = {
    project     = data.external.gcp_fetch_cloud_secret.result["project"]
    credentials = sensitive(data.external.gcp_fetch_cloud_secret.result["serviceAccountKey"])
    secrets = [
      "credentials"
    ]
  }
}
