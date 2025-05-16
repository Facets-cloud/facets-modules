# Log Collector – Loki Flavor (v0.2)

## Overview

The `log_collector - loki` flavor (v0.2) enables the collection and management of logs using Loki within various cloud environments. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- AWS  
- Azure  
- GCP  
- Kubernetes

## Configurability

### Spec

#### `retentation_days` (`integer`)

Defines the number of days logs are retained.

- **Title**: Retention Days
- **Description**: Retention days after which the logs should be deleted
- **Pattern**: `^[0-9]+$`
- **UI Placeholder**: "Enter the number of days for log retention"
- **UI Error Message**: "Only numeric values are allowed."

#### `storage_size` (`string`)

Specifies the size of the storage allocated for logs.

- **Title**: Storage Size
- **Description**: Storage size for MinIO where the logs are stored

---

## Usage

Use this module to collect and manage logs using Loki in various cloud environments. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
