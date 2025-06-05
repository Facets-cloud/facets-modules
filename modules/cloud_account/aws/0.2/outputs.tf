locals {
  session_name      = "${var.instance.spec.role_session_name}-${uuid()}"
  output_interfaces = {}
  output_attributes = {
    aws_iam_role = sensitive(var.instance.spec.role_arn)
    session_name = sensitive(local.session_name)
    external_id  = sensitive(var.instance.spec.external_id)
    aws_region   = var.instance.spec.region
    secrets = [
      "aws_iam_role",
      "session_name",
      "external_id",
    ]
  }
}
