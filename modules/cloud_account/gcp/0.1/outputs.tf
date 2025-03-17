locals {
  output_interfaces = {}
  output_attributes = {
    project     = lookup(local.cluster, "project", "")
    region      = lookup(local.cluster, "region", "")
    credentials = sensitive(base64decode(lookup(local.cluster, "serviceAccountKey", "")))
    secrets = [
      "project",
      "credentials",
    ]
  }
}
