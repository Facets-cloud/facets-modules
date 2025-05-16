# Log Collector – Loki GCP GCS Flavor (v0.2)

## Overview

The `log_collector - loki_gcp_gcs` flavor (v0.2) enables the collection and management of logs using Loki with Google Cloud Storage (GCS) within various cloud environments. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- GCP  
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

#### `loki_gcs` (object)

Provides configuration options for Loki with Google Cloud Storage (GCS).

---

## Usage

Use this module to collect and manage logs using Loki with Google Cloud Storage (GCS) in various cloud environments. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
