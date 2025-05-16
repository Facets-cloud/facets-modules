# Log Collector – Loki AWS S3 Flavor (v0.1)

## Overview

The `log_collector - loki_aws_s3` flavor (v0.1) enables the collection and management of logs using Loki with AWS S3 storage. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- AWS

## Configurability

### Spec

#### `retentation_days` (`integer`)

Defines the number of days logs are retained.

#### `storage_size` (`string`)

Specifies the size of the storage allocated for logs.

---

### Advanced Configuration

#### `loki_s3` (object)

Provides configuration options for Loki with AWS S3 storage.

- **bucket_name** (`string`): The name of the S3 bucket used for log storage.

---

## Usage

Use this module to collect and manage logs using Loki with AWS S3 storage. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
