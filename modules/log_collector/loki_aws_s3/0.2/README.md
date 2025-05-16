# Log Collector – Loki AWS S3 Flavor (v0.2)

## Overview

The `log_collector - loki_aws_s3` flavor (v0.2) enables the collection and management of logs using Loki with AWS S3 storage within various cloud environments. This module provides structured log collection, storage, and querying capabilities.

Supported platforms:
- AWS  
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

#### `loki_s3` (object)

Provides configuration options for Loki with AWS S3 storage.

---

## Usage

Use this module to collect and manage logs using Loki with AWS S3 storage in various cloud environments. It is especially useful for:

- Structured log collection
- Log storage and querying
- Enhancing observability and monitoring
