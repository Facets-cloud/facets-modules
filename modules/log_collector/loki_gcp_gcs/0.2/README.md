# Log Collector Module (Loki GCP GCS Flavor)

## Overview

The `log_collector - loki_gcp_gcs` flavor (v0.2) enables the deployment and management of log collection infrastructure using Loki with Google Cloud Storage (GCS) as the storage backend. This module provides a cloud-native logging solution specifically optimized for GCP environments, leveraging GCS for scalable and cost-effective log storage.

Supported clouds:
- GCP
- Kubernetes

## Configurability

- **Advanced Configuration**: GCP GCS-specific Loki configuration for seamless integration with Google Cloud Storage services

## Usage

Use this module to implement centralized logging using Loki with Google Cloud Storage backend. It is especially useful for:

- Collecting and aggregating logs from GCP-hosted applications and services
- Leveraging Google Cloud Storage for cost-effective, scalable log storage
- Implementing log retention policies with GCS lifecycle management
- Supporting observability and monitoring workflows in GCP and Kubernetes environments
- Integrating with existing Google Cloud logging and monitoring infrastructure
- Providing durable and highly available log storage using Google Cloud Storage
