# Google Cloud Storage - Default Flavor

## Overview

The `google_cloud_storage` intent with the `default` flavor provisions a Google Cloud Storage (GCS) bucket with configurable features such as storage class, versioning, lifecycle policies, and access controls. It enables automated, consistent, and policy-driven bucket creation across GCP environments.

## Configurability

- **location** (`string`): Region for bucket creation (e.g., `US`, `EU`, `ASIA`).
- **storage_class** (`string`): Storage tier (`STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`).
- **versioning_enabled** (`boolean`): Toggle for object versioning.
- **lifecycle_rules** (`object`):
  - `enabled`: Enable/disable lifecycle rules.
  - `age_days`: Age (in days) for lifecycle action.
  - `action`: Action to perform (`Delete` or `SetStorageClass`).
  - `storage_class`: Target storage class if using `SetStorageClass`.
- **uniform_bucket_level_access** (`boolean`): Enforces uniform access control.
- **custom_labels** (`object`): Key-value metadata tags.
- **requester_pays** (`boolean`): Enables Requester Pays model.

## Usage

Use this module to automate GCS bucket creation and management with built-in support for security policies, lifecycle automation, and storage tiering. It supports IAM outputs for read-only and read-write access and integrates with GCP IAM condition expressions for granular access control.
