# Log Collector – Loki Azure Blob Flavor (v0.1)

## Overview

The `log_collector - loki_azure_blob` flavor (v0.1) enables the collection and management of logs using Loki with Azure Blob storage. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- Azure

## Configurability

### Spec

#### `retentation_days` (`integer`)

Defines the number of days logs are retained.

#### `storage_size` (`string`)

Specifies the size of the storage allocated for logs.

---

### Advanced Configuration

#### `loki_blob` (object)

Provides configuration options for Loki with Azure Blob storage.

- **container_name** (`string`): The name of the Azure Blob storage container.
- **primary_access_key** (`string`): The access key for the Azure Blob storage container.
- **storage_account_name** (`string`): The name of the Azure Storage Account.

---

## Usage

Use this module to collect and manage logs using Loki with Azure Blob storage. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
