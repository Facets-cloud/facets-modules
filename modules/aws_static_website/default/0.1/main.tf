module "name" {
  source          = "../../3_utility/name"
  is_k8s          = false
  globally_unique = true
  resource_name   = var.instance_name
  resource_type   = "aws_static_website"
  limit           = 40
  environment     = var.environment
}

module "s3name" {
  source          = "../../3_utility/name"
  is_k8s          = false
  globally_unique = true
  resource_type   = "s3"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 63
}

data "aws_s3_bucket" "customer-bucket" {
  bucket   = var.cc_metadata.customer_artifact_bucket
  provider = aws.tooling
}

data "aws_s3_bucket_object" "customer-bucket-object" {
  depends_on = [data.aws_s3_bucket.customer-bucket]
  count      = local.s3_key != null && local.s3_key != "" ? 1 : 0
  bucket     = data.aws_s3_bucket.customer-bucket.id
  key        = local.s3_key
  provider   = aws.tooling
}

resource "null_resource" "download_s3_zips" {
  triggers = {
    aws_zip = local.s3_key != null && local.s3_key != "" ? data.aws_s3_bucket_object.customer-bucket-object.0.version_id : null
  }
  depends_on = [data.aws_s3_bucket_object.customer-bucket-object, data.aws_s3_bucket.customer-bucket]

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/${local.dir_name}/unzipped &&
      aws s3api get-object --bucket ${data.aws_s3_bucket.customer-bucket.id} --key ${local.s3_key} --region ${var.cc_metadata.cc_region} ${path.module}/${local.dir_name}/${local.s3_key} &&
      unzip ${path.module}/${local.dir_name}/${local.s3_key} -d ${path.module}/${local.dir_name}/unzipped &&
      rm ${path.module}/${local.dir_name}/${local.s3_key}
    EOF
  }
}

module "s3" {
  depends_on = [null_resource.download_s3_zips]
  for_each   = local.s3_details
  source     = "../../aws_s3"
  instance = {
    "advanced" = {
      "s3" = each.value
    }
  }
  instance_name = "${var.instance_name}-${each.value.bucket}"
  environment   = var.environment
  cluster       = var.cluster
  baseinfra     = var.baseinfra
  cc_metadata   = var.cc_metadata
}

resource "null_resource" "upload_sync_s3_files" {
  depends_on = [null_resource.download_s3_zips, module.s3]
  for_each   = local.s3_details

  triggers = {
    aws_zip = local.s3_key != null && local.s3_key != "" ? data.aws_s3_bucket_object.customer-bucket-object.0.version_id : null
  }

  provisioner "local-exec" {
    command = <<EOF
      set -e &&
      iamrole=$(cat /sources/deployment_context/deploymentcontext.json | jq .cluster.roleARN -r) &&
      externalid=$(cat /sources/deployment_context/deploymentcontext.json | jq .cluster.externalId -r) &&
      creds=$(aws sts assume-role --role-arn $iamrole --role-session-name k8supgrade --external-id $externalid) &&
      aws configure set profile.${each.key}.aws_access_key_id $(echo $creds | jq .Credentials.AccessKeyId -r) &&
      aws configure set profile.${each.key}.aws_secret_access_key $(echo $creds | jq .Credentials.SecretAccessKey -r) &&
      aws configure set profile.${each.key}.aws_session_token $(echo $creds | jq .Credentials.SessionToken -r) &&
      aws configure set profile.${each.key}.region $(cat /sources/deployment_context/deploymentcontext.json | jq .cluster.awsRegion -r) &&
      aws s3 sync ${path.module}/${local.dir_name}/unzipped/ s3://${module.s3[each.key].bucket_name}/ --delete --profile ${each.key}
    EOF
  }
}

module "cloudfront" {
  count         = local.cloudfront_enabled ? 1 : 0
  source        = "../../1_input_instance/aws_cloudfront"
  instance      = local.cloudfront_details
  instance_name = var.instance_name
  environment   = var.environment
  cluster       = var.cluster
  baseinfra     = var.baseinfra
  cc_metadata   = var.cc_metadata
}

resource "aws_s3_bucket_policy" "cloudfront_read_acces_bucket_policy" {
  provider = aws4
  count    = local.cloudfront_enabled ? 1 : 0
  bucket   = module.s3[module.s3name.name].bucket_name
  policy   = data.aws_iam_policy_document.cloudfront_oai_bucket_policy.0.json
}

data "aws_iam_policy_document" "cloudfront_oai_bucket_policy" {
  count = local.cloudfront_enabled ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = ["${module.cloudfront.0.cloudfront_origin_access_identity_iam_arns.0}"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = ["${module.s3[module.s3name.name].bucket_arn}/*"]
  }
}
