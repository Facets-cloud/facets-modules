data "external" "gcp_fetch_cloud_secret" {
  program = [
    "python3",
    "/sources/primary/capillary-cloud-tf/tfmain/scripts/cloudaccount-fetch-secret/secret-fetcher.py",
    var.instance.spec.cloud_account,
    "GCP"
  ]
}
