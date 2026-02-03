locals {
  output_interfaces = {}
  output_attributes = {
    policy_id = aws_dlm_lifecycle_policy.dlm-lifecycle-policy.id
  }
}