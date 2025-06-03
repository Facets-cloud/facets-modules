module "unique_name" {
  count           = local.name_override_present ? 0 : 1
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "iam_user"
  is_k8s          = false
  globally_unique = true
}

resource "aws_iam_user" "iam_user" {
  name          = local.name_override_present ? local.user_name : module.unique_name[0].name
  path          = local.path
  force_destroy = false
  tags          = local.tags
}

resource "aws_iam_access_key" "iam_user_key" {
  user = aws_iam_user.iam_user.name
}

resource "aws_iam_user_policy_attachment" "predefined_policies" {
  for_each   = local.policy_arns
  user       = aws_iam_user.iam_user.name
  policy_arn = each.value
}

resource "aws_iam_user_policy" "custom_policies" {
  for_each = local.custom_policies
  name     = each.value.name
  user     = aws_iam_user.iam_user.name
  policy   = each.value.policy
}
