data "external" "aws_fetch_cloud_secret" {
  program = [
    "python3",
    "/sources/primary/capillary-cloud-tf/tfmain/scripts/cloudaccount-fetch-secret/secret-fetcher.py",
    var.instance.spec.cloud_account,
    "AWS"
  ]
}

# Output the parsed result as locals
locals {
  script_output = {
    aws_iam_role = data.external.aws_fetch_cloud_secret.result["iamRole"]
    external_id  = data.external.aws_fetch_cloud_secret.result["externalId"]
    aws_region   = var.instance.spec.region
  }
}