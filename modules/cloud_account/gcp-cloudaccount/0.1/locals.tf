data "external" "gcp_fetch_cloud_secret" {
  program = [
    "python3",
    "/sources/primary/capillary-cloud-tf/tfmain/scripts/cloudaccount-fetch-secret/secret-fetcher.py",
    # "${path.module}/fetch-gcp-secret-v2.py",
    var.instance.spec.cloud_account
  ]
}
