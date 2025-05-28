# Log Collector Module (Loki Flavor)

## Overview

The `log_collector - loki` flavor (v0.2) enables the deployment and management of log collection infrastructure using Loki in Kubernetes and cloud environments. This module provides a comprehensive logging solution that collects, processes, stores, and queries logs from various sources within your infrastructure.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Retention Days**: Number of days to retain logs before deletion. Only numeric values are allowed (e.g., 7 days)
- **Storage Size**: Storage size for MinIO where the logs are stored (e.g., "5Gi")
- **Advanced Configuration**: Additional Loki-specific configuration options for fine-tuning the log collection system

## Usage

Use this module to implement centralized logging using Loki for your infrastructure. It is especially useful for:

- Collecting and aggregating logs from distributed applications and services
- Providing scalable log storage with configurable retention policies
- Enabling efficient log querying and analysis across multi-cloud environments
- Supporting observability and monitoring workflows
- Maintaining compliance with log retention requirements
- Integrating with existing Kubernetes and cloud-native logging pipelines
