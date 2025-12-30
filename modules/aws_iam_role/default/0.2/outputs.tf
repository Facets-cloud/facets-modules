# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    irsa_iam_role_arn = length(local.irsa) > 0 ? module.iam_eks_role.0.iam_role_arn : null
    iam_role_name = module.iam_eks_role.iam_role_name
    iam_role_arn = module.iam_eks_role.iam_role_arn
  }
}

output "irsa_iam_role_arn" {
  value = length(local.irsa) > 0 ? module.iam_eks_role.0.iam_role_arn : null
}
