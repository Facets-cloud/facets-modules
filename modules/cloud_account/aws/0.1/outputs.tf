locals {
  output_interfaces = {}
  output_attributes = {
    aws_iam_role = sensitive(lookup(local.cluster, "roleARN", ""))
    session_name = "capillary-cloud-tf-${uuid()}"
    external_id  = sensitive(lookup(local.cluster, "externalId", ""))
    aws_region   = lookup(local.cluster, "awsRegion", "")
    account_id   = local.account_id
    secrets = [
      "aws_iam_role", 
      "session_name",
      "external_id",
    ]
  }
}
