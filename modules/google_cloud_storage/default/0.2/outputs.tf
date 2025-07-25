locals {
  output_attributes = {
    name = google_storage_bucket.bucket.name
    url = "gs://${google_storage_bucket.bucket.name}"
    bucket_url                      = "gs://${google_storage_bucket.bucket.name}"
    bucket_name                     = google_storage_bucket.bucket.name
    read_only_role                  = "roles/storage.objectViewer"
    bucket_location                 = google_storage_bucket.bucket.location
    read_write_role                 = "roles/storage.objectAdmin"
    bucket_self_link                = google_storage_bucket.bucket.self_link
    bucket_storage_class            = google_storage_bucket.bucket.storage_class
    bucket_iam_condition_title      = "Restrict to ${google_storage_bucket.bucket.name} bucket"
    bucket_iam_condition_expression = "resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.bucket.name}\")"
  }
  output_interfaces = {
  }
}
