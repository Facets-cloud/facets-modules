# Log Collector – Loki Azure Blob Flavor (v0.2)

## Overview

The `log_collector - loki_azure_blob` flavor (v0.2) enables the collection and management of logs using Loki with Azure Blob storage within various cloud environments. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- Azure  
- Kubernetes

## Configurability

### Spec

#### `title` (`string`)

Title of the Log Collector Spec.

#### `type` (`string`)

Type of the Log Collector Spec.

#### `description` (`string`)

Description of the Log Collector Spec.

---

### Advanced Configuration

#### `loki_blob` (object)

Provides configuration options for Loki with Azure Blob storage.

---

## Usage

Use this module to collect and manage logs using Loki with Azure Blob storage in various cloud environments. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
