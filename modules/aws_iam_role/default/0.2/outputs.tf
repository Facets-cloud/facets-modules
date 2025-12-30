# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    irsa_iam_role_arn = module.iam_eks_role.0.iam_role_arn
    iam_role_name = module.iam_eks_role.0.iam_role_name
    iam_role_arn = module.iam_eks_role.0.iam_role_arn
  }
}

output "irsa_iam_role_arn" {
  value = module.iam_eks_role.0.iam_role_arn
}
