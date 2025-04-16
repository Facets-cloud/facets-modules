locals {
  output_interfaces = {}
  output_attributes = {
    project     = lookup(local.cluster, "project", "")
    region      = lookup(local.cluster, "region", "")
    credentials = file("/gcp-credentials.json")
    secrets = [
      "project",
      "credentials",
    ]
  }
}
