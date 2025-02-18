locals {
  output_interfaces = {}
  output_attributes = {
    aws_iam_role = lookup(local.cluster, "roleARN", "")
    session_name = "capillary-cloud-tf-${uuid()}"
    external_id  = lookup(local.cluster, "externalId", "")
    aws_region   = lookup(local.cluster, "awsRegion", "")
  }
}
