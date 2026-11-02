locals {
  output_interfaces = {}
  output_attributes = {
    aws_iam_role = sensitive(local.script_output.aws_iam_role)
    session_name = "capillary-cloud-tf-${uuid()}"
    external_id  = sensitive(local.script_output.external_id)
    aws_region   = local.script_output.aws_region
    secrets = [
      "external_id"
    ]
  }
}
