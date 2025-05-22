locals {
  output_interfaces = {}
  gcp_output_attributes = {
    project     = lookup(local.cluster, "project", "")
    region      = lookup(local.cluster, "region", "")
    credentials = sensitive("/gcp-credentials.json")
    secrets = [
      "project",
      "credentials",
    ]
  }
  azure_output_attributes = {
    subscription_id = sensitive(lookup(local.cluster, "subscriptionId", ""))
    client_id       = sensitive(lookup(local.cluster, "clientId", ""))
    client_secret   = sensitive(lookup(local.cluster, "clientSecret", ""))
    tenant_id       = sensitive(lookup(local.cluster, "tenantId", ""))
    secrets = [
      "subscription_id",
      "client_id",
      "client_secret",
      "tenant_id",
    ]
  }
  aws_output_attributes = {
    aws_iam_role = sensitive(lookup(local.cluster, "roleARN", ""))
    session_name = "capillary-cloud-tf-${uuid()}"
    external_id  = sensitive(lookup(local.cluster, "externalId", ""))
    aws_region   = lookup(local.cluster, "awsRegion", "")
    secrets = [
      "aws_iam_role",
      "session_name",
      "external_id",
    ]
  }

  output_attributes = {}
  #  output_attributes = local.cluster == "aws" ? {
  #    aws_iam_role = sensitive(lookup(local.cluster, "roleARN", ""))
  #    session_name = "capillary-cloud-tf-${uuid()}"
  #    external_id  = sensitive(lookup(local.cluster, "externalId", ""))
  #    aws_region   = lookup(local.cluster, "awsRegion", "")
  #    secrets = [
  #      "aws_iam_role",
  #      "session_name",
  #      "external_id",
  #    ]
  #    } : local.cloud == "azure" ? {
  #    subscription_id = sensitive(lookup(local.cluster, "subscriptionId", ""))
  #    client_id       = sensitive(lookup(local.cluster, "clientId", ""))
  #    client_secret   = sensitive(lookup(local.cluster, "clientSecret", ""))
  #    tenant_id       = sensitive(lookup(local.cluster, "tenantId", ""))
  #    secrets = [
  #      "subscription_id",
  #      "client_id",
  #      "client_secret",
  #      "tenant_id",
  #    ]
  #    } : {
  #    project     = lookup(local.cluster, "project", "")
  #    region      = lookup(local.cluster, "region", "")
  #    credentials = sensitive("/gcp-credentials.json")
  #    secrets = [
  #      "project",
  #      "credentials",
  #    ]
  #  }
}
