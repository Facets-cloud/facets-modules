# GCP Service Account Impersonation Module

This Facets Cloud module enables service account impersonation in Google Cloud Platform (GCP). It's designed to securely obtain short-lived access tokens by impersonating a designated service account, following GCP's security best practices.

## Overview

The `cloud_account/impersonate` module allows your Facets blueprint to temporarily assume the identity and permissions of a specified GCP service account. This pattern is useful for implementing the principle of least privilege while still allowing your workloads to access necessary GCP resources.

## Features

- Secure service account impersonation using short-lived tokens (1800s/30 minutes)
- Compatible with multiple Google provider versions
- Provides access tokens that can be used with various Google Cloud APIs
- Follows GCP security best practices

## Requirements

- A valid GCP service account with appropriate permissions
- The caller must have the `iam.serviceAccounts.actAs` permission on the target service account

## Usage

```hcl
module "gcp_impersonation" {
  kind    = "cloud_account"
  flavor  = "impersonate"
  version = "1.0"
  spec = {
    service_account = "terraform@your-project-id.iam.gserviceaccount.com"
  }
}
```

## Specification Parameters

| Parameter | Description | Required | Format |
|-----------|-------------|----------|--------|
| `service_account` | The email address of the service account to impersonate | Yes | Must match the pattern of a valid GCP service account email |

## Outputs

The module outputs access tokens that can be used with Google Cloud providers:

| Output | Description |
|--------|-------------|
| `access_token` | The short-lived access token obtained through impersonation |

## Provider Configuration

This module automatically configures the following providers with the impersonated credentials:

- `google` (version 6.23.0)
- `google-beta` (version 6.23.0)
- `google5` (version 5.32.0)

## Security Considerations

- The access tokens are valid for 30 minutes (1800 seconds)
- Always follow the principle of least privilege when assigning roles to the impersonated service account
- Ensure proper IAM permissions are set on the target service account

## License

This module is part of the Facets Cloud platform.
